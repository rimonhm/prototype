PROC SQL;
   CREATE TABLE WORK.for_varmax_AP_NRBACC AS 
   SELECT t1.USE, 
t1.premixed_concrete_usage,
          t1.sales_territory_name, 
/*          t1.market_segment_name, */
          t1.TO_PRED_PMC as Y1, 
/*          t1.TO_PRED_PCC as Y2, */
/*          t1.TO_PRED_C as Y3, */
/*          t1.TO_PRED_A as Y4, */
/*          t1.TO_PRED_RB as Y5, */
/*          t1.TO_PRED_CA as Y6, */
/*          t1.TO_PRED_CS as Y7, */
          t1.value_of_work_done
      FROM WORK.AP_NRBACC t1
/*	  where sales_territory_name = 'Brisbane Inner City'*/
order by sales_territory_name, t1.use;
QUIT;



proc timeseries data=for_varmax_AP_NRBACC vectorplot=series;
   id USE interval=qtr;
   var Y1 Y2 Y3 Y6 Y7;
run;

proc timeseries data=for_varmax_AP_NRBACC vectorplot=series;
   id USE interval=qtr;
   var Y1;
run;

proc varmax data=for_varmax_AP_NRBACC;
   id use interval=qtr;
   model  Y1 Y2 Y3 Y6 Y7 / p=2 Trend=Linear;
/*   cointeg rank=1 normalize=y1 exogeneity;*/
/*   output out=forecasts lead=12 ;*/
run;




ODS GRAPHICS ON;
proc ucm data=for_varmax_AP_NRBACC plots=none;
autoreg noest=rho rho=0.99; 
cycle period=3 rho=0.3 variance=8 noest=(rho period);
deplag lags=(1)(2) phi=0.3 0.3 noest;
id use interval=qtr;
model Y1= value_of_work_done;
By sales_territory_name;
/*estimate skipfirst=3 back=36;*/
irregular 
p=1 sp=1 q=1 sq=1 s=1 sma=0.17 noest=(sma)
;
level variance=3 noest print=filter;
slope;
forecast lead=12 outfor=ucmtest (keep=sales_territory_name use forecast Y1);
run;
ODS GRAPHICS OFF;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_UCMTEST AS 
   SELECT t1.sales_territory_name, 
          t1.use, 
          t1.Y1, 
          t1.FORECAST, 
          t2.premixed_concrete_usage
      FROM WORK.UCMTEST t1, WORK.FOR_VARMAX_AP_NRBACC t2
      WHERE (t1.use = t2.use AND t1.sales_territory_name = t2.sales_territory_name);
QUIT;







proc varmax data=FILTER_FOR_FOR_VARMAX_AP_NRBACC;
   id use interval=qtr;
   model Y1 = hod_total_dwellings_approved hod_avg_floor_area / p=(1) dify=(1)
/*                 print=(decompose(6) impulse=(stderr) estimates diagnose)*/
                 printform=both lagmax=3 xlag=2 method=ls;
				 NLOPTIONS tech=qn;
				 BY sales_territory_name;
/*   causal group1=(Y1);*/
   output  out=pred noprint alpha=0.05 back=6 lead=36;
run;