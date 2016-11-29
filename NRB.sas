	%macro s5(ot=, P=, S=, F=, MM=, OO=);
PROC SORT
	DATA=WORK.&ot.(KEEP=quarter_date
	precast_concrete_usage cement_usage asphalt_usage road_base_usage coarse_aggregate_usage
    construction_sand_usage premixed_concrete_usage TO_PRED_PMC TO_PRED_PCC TO_PRED_C TO_PRED_A TO_PRED_RB TO_PRED_CA TO_PRED_CS
	value_of_work_done
	use sales_territory_name)
	OUT=SORTTEMP
	;
	BY sales_territory_name use;
RUN;

PROC AUTOREG DATA = SORTTEMP 	
;
	BY sales_territory_name;
	MODEL &MM = quarter_date value_of_work_done/
	METHOD=ML
	MAXITER=50
	nlag=(4 8 12 12 8)backstep
	;
		OUTPUT OUT=MM.&OO.

		LCLM=LCLM UCLM=UCLM PM=PREDICTED RM=RESIDUALM
		ALPHACLM=0.05
	;
RUN;QUIT;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;

data work.&F.;
set MM.&OO. 
;
segement=&S;
product=&P;
run; 

%mend s5;
%s5(ot=ap_NRBACC	,	 MM=TO_PRED_PMC		,	 OO=PRED_NRBACCPMC	,	F=f1 , 	P='premixed_concrete',	S='ACC')	;
%s5(ot=ap_NRBEDU	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBEDUPMC	,	F=f2 , 	P='premixed_concrete',	S='EDU')	;
%s5(ot=ap_NRBENT	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBENTPMC	,	F=f3 , 	P='premixed_concrete',	S='ENT')	;
%s5(ot=ap_NRBIND	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBINDPMC	,	F=f4 , 	P='premixed_concrete',	S='IND')	;
%s5(ot=ap_NRBHEA	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBHEAPMC	,	F=f5 , 	P='premixed_concrete',	S='HEA')	;
%s5(ot=ap_NRBOFF	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBOFFPMC	,	F=f6 , 	P='premixed_concrete',	S='OFF')	;
%s5(ot=ap_NRBCOT	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBCOTPMC	,	F=f7 , 	P='premixed_concrete',	S='COT')	;
%s5(ot=ap_NRBREL	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBRELPMC	,	F=f8 , 	P='premixed_concrete',	S='REL')	;
%s5(ot=ap_NRBCOM	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBCOMPMC	,	F=f9 , 	P='premixed_concrete',	S='COM')	;
%s5(ot=ap_NRBSOC	,	 MM=TO_PRED_PMC 	,	 OO=PRED_NRBSOCPMC	,	F=f10 , P='premixed_concrete',	S='SOC')	;

data MM.F_NRB1;
set f1	f2	f3	f4	f5	f6	f7	f8	f9	f10	
;
run;

	%macro s5(ot=, P=, S=, F=, MM=, OO=);
PROC SORT
	DATA=WORK.&ot.(KEEP=quarter_date
	precast_concrete_usage cement_usage asphalt_usage road_base_usage coarse_aggregate_usage
    construction_sand_usage premixed_concrete_usage TO_PRED_PMC TO_PRED_PCC TO_PRED_C TO_PRED_A TO_PRED_RB TO_PRED_CA TO_PRED_CS
	value_of_work_done
	use sales_territory_name)
	OUT=SORTTEMP
	;
	BY sales_territory_name use;
RUN;

PROC AUTOREG DATA = SORTTEMP 	
;
	BY sales_territory_name;
	MODEL &MM = quarter_date value_of_work_done/
	METHOD=ML
	MAXITER=50
	nlag=(4 8 12 12 8)backstep
	
	;
		OUTPUT OUT=MM.&OO.

		LCLM=LCLM UCLM=UCLM PM=PREDICTED RM=RESIDUALM
		ALPHACLM=0.05
	;
RUN;QUIT;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;

data work.&F.;
set MM.&OO. 
;
segement=&S;
product=&P;
run; 

%mend s5;

%s5(ot=ap_NRBACC	,	 MM=TO_PRED_PCC		,	 OO=PRED_NRBACCPCC	,	F=f11 , 	P='precast_concrete',	S='ACC')	;
%s5(ot=ap_NRBEDU	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBEDUPCC	,	F=f12 , 	P='precast_concrete',	S='EDU')	;
%s5(ot=ap_NRBENT	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBENTPCC	,	F=f13 , 	P='precast_concrete',	S='ENT')	;
%s5(ot=ap_NRBIND	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBINDPCC	,	F=f14 , 	P='precast_concrete',	S='IND')	;
%s5(ot=ap_NRBHEA	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBHEAPCC	,	F=f15 , 	P='precast_concrete',	S='HEA')	;
%s5(ot=ap_NRBOFF	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBOFFPCC	,	F=f16 , 	P='precast_concrete',	S='OFF')	;
%s5(ot=ap_NRBCOT	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBCOTPCC	,	F=f17 , 	P='precast_concrete',	S='COT')	;
%s5(ot=ap_NRBREL	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBRELPCC	,	F=f18 , 	P='precast_concrete',	S='REL')	;
%s5(ot=ap_NRBCOM	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBCOMPCC	,	F=f19 , 	P='precast_concrete',	S='COM')	;
%s5(ot=ap_NRBSOC	,	 MM=TO_PRED_PCC 	,	 OO=PRED_NRBSOCPCC	,	F=f20 , 	P='precast_concrete',	S='SOC')	;

data MM.F_NRB2;
set f11	f12	f13	f14	f15	f16	f17	f18	f19	f20	
;
run;

	%macro s5(ot=, P=, S=, F=, MM=, OO=);
PROC SORT
	DATA=WORK.&ot.(KEEP=quarter_date
	precast_concrete_usage cement_usage asphalt_usage road_base_usage coarse_aggregate_usage
    construction_sand_usage premixed_concrete_usage TO_PRED_PMC TO_PRED_PCC TO_PRED_C TO_PRED_A TO_PRED_RB TO_PRED_CA TO_PRED_CS
	value_of_work_done
	use sales_territory_name)
	OUT=SORTTEMP
	;
	BY sales_territory_name use;
RUN;

PROC AUTOREG DATA = SORTTEMP 	
;
	BY sales_territory_name;
	MODEL &MM = quarter_date value_of_work_done/
	METHOD=ML
	MAXITER=50
	
	;
		OUTPUT OUT=MM.&OO.

		LCLM=LCLM UCLM=UCLM PM=PREDICTED RM=RESIDUALM
		ALPHACLM=0.05
	;
RUN;QUIT;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;

data work.&F.;
set MM.&OO. 
;
segement=&S;
product=&P;
run; 

%mend s5;

%s5(ot=ap_NRBACC	,	 MM=TO_PRED_C	,	 OO=PRED_NRBACCD_C	,	F=f21 , 	P='cement',	S='ACC')	;
%s5(ot=ap_NRBEDU	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBEDUD_C	,	F=f22 , 	P='cement',	S='EDU')	;
%s5(ot=ap_NRBENT	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBENTD_C	,	F=f23 , 	P='cement',	S='ENT')	;
%s5(ot=ap_NRBIND	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBINDD_C	,	F=f24 , 	P='cement',	S='IND')	;
%s5(ot=ap_NRBHEA	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBHEAD_C	,	F=f25 , 	P='cement',	S='HEA')	;
%s5(ot=ap_NRBOFF	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBOFFD_C	,	F=f26 , 	P='cement',	S='OFF')	;
%s5(ot=ap_NRBCOT	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBCOTD_C	,	F=f27 , 	P='cement',	S='COT')	;
%s5(ot=ap_NRBREL	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBRELD_C	,	F=f28 , 	P='cement',	S='REL')	;
%s5(ot=ap_NRBCOM	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBCOMD_C	,	F=f29 , 	P='cement',	S='COM')	;
%s5(ot=ap_NRBSOC	,	 MM=TO_PRED_C 	,	 OO=PRED_NRBSOCD_C	,	F=f30 , 	P='cement',	S='SOC')	;

data MM.F_NRB3;
set f21	f22	f23	f24	f25	f26	f27	f28	f29	f30	
;
run;
%macro s5(ot=, P=, S=, F=, MM=, OO=);
PROC SORT
	DATA=WORK.&ot.(KEEP=quarter_date
	precast_concrete_usage cement_usage asphalt_usage road_base_usage coarse_aggregate_usage
    construction_sand_usage premixed_concrete_usage TO_PRED_PMC TO_PRED_PCC TO_PRED_C TO_PRED_A TO_PRED_RB TO_PRED_CA TO_PRED_CS
	value_of_work_done
	use sales_territory_name)
	OUT=SORTTEMP
	;
	BY sales_territory_name use;
RUN;

PROC AUTOREG DATA = SORTTEMP 	
;
	BY sales_territory_name;
	MODEL &MM = quarter_date value_of_work_done/
	METHOD=ML
	MAXITER=50
	;
		OUTPUT OUT=MM.&OO.

		LCLM=LCLM UCLM=UCLM PM=PREDICTED RM=RESIDUALM
		ALPHACLM=0.05
	;
RUN;QUIT;
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;

data work.&F.;
set MM.&OO. 
;
segement=&S;
product=&P;
run; 

%mend s5;
%s5(ot=ap_NRBEDU	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBEDU_CA	,	F=f62 , 	P='coarse_aggregate',	S='EDU')	;
%s5(ot=ap_NRBENT	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBENT_CA	,	F=f63 , 	P='coarse_aggregate',	S='ENT')	;
%s5(ot=ap_NRBIND	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBIND_CA	,	F=f64 , 	P='coarse_aggregate',	S='IND')	;
%s5(ot=ap_NRBHEA	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBHEA_CA	,	F=f65 , 	P='coarse_aggregate',	S='HEA')	;
%s5(ot=ap_NRBOFF	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBOFF_CA	,	F=f66 , 	P='coarse_aggregate',	S='OFF')	;
%s5(ot=ap_NRBCOT	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBCOT_CA	,	F=f67 , 	P='coarse_aggregate',	S='COT')	;
%s5(ot=ap_NRBREL	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBREL_CA	,	F=f68 , 	P='coarse_aggregate',	S='REL')	;
%s5(ot=ap_NRBCOM	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBCOM_CA	,	F=f69 , 	P='coarse_aggregate',	S='COM')	;
%s5(ot=ap_NRBSOC	,	 MM=TO_PRED_CA 	,	 OO=PRED_NRBSOC_CA	,	F=f70 , 	P='coarse_aggregate',	S='SOC')	;
%s5(ot=ap_NRBACC	,	 MM=TO_PRED_CS	,	 OO=PRED_NRBACC_CS	,	F=f71 , 	P='construction_sand',	S='ACC')	;
%s5(ot=ap_NRBEDU	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBEDU_CS	,	F=f72 , 	P='construction_sand',	S='EDU')	;
%s5(ot=ap_NRBENT	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBENT_CS	,	F=f73 , 	P='construction_sand',	S='ENT')	;
%s5(ot=ap_NRBIND	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBIND_CS	,	F=f74 , 	P='construction_sand',	S='IND')	;
%s5(ot=ap_NRBHEA	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBHEA_CS	,	F=f75 , 	P='construction_sand',	S='HEA')	;
%s5(ot=ap_NRBOFF	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBOFF_CS	,	F=f76 , 	P='construction_sand',	S='OFF')	;
%s5(ot=ap_NRBCOT	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBCOT_CS	,	F=f77 , 	P='construction_sand',	S='COT')	;
%s5(ot=ap_NRBREL	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBREL_CS	,	F=f78 , 	P='construction_sand',	S='REL')	;
%s5(ot=ap_NRBCOM	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBCOM_CS	,	F=f79 , 	P='construction_sand',	S='COM')	;
%s5(ot=ap_NRBSOC	,	 MM=TO_PRED_CS 	,	 OO=PRED_NRBSOC_CS	,	F=f80 , 	P='construction_sand',	S='SOC')	;



data MM.F_NRB4;
set f62	f63	f64	f65	f66	f67	f68	f69	f70	f71	f72	f73	f74	f75	f76	f77	f78	f79	f80
;
run;

proc datasets lib=work nolist;
delete SORTTEMP work.&F.;
quit;
run;



%macro s5(MM=, F=, P=);
PROC SQL;
   CREATE TABLE work.&F. AS 
   SELECT quarter_date, 
          use, 
          sales_territory_name, 
          product, 
          &MM as DEMAND_ORIGINAL, 
          PREDICTED, 
          /* Market Segment */
            (case when segement = "ACC" then 'NonRES_ACCOMMODATION' 
			when segement = "EDU" then 'NonRES_EDUCATION' 
			when segement = "ENT" then 'NonRES_ENTERTAINMENT' 
			when segement = "IND" then 'NonRES_FACTORY' 
			when segement = "HEA" then 'NonRES_HEALTH' 
			when segement = "OFF" then 'NonRES_OFFICE' 
			when segement = "COT" then 'NonRES_OTHER_BUSINESS_PREMISES' 
			when segement = "REL" then 'NonRES_RELIGION' 
			when segement = "COM" then 'NonRES_RETAIL'
			when segement = "SOC" then 'NonRES_SOCIAL'
			else '' end) AS 'Market Segment'n
      FROM MM.F_NRB
      WHERE product = &P;
QUIT;
/*ACCOMMODATION	ACC*/
/*EDUCATION	EDU*/
/*ENTERTAINMENT	ENT*/
/*FACTORY	IND*/
/*HEALTH	HEA*/
/*OFFICE	OFF*/
/*OTHER BUSINESS PREMISES	COT*/
/*RELIGION	REL*/
/*RETAIL	COM*/
/*SOCIAL/OTHER	SOC*/
%mend s5;
%s5	(MM=premixed_concrete_usage, F=f1, P= 'premixed_concrete' )	; 
%s5	(MM=precast_concrete_usage, F=f2, P= 'precast_concrete' )	;
%s5	(MM=cement_usage, F=f3, P= 'cement' 	)	;
%s5	(MM=asphalt_usage, F=f4, P= 'asphalt' 	)	;
%s5	(MM=road_base_usage, F=f5, P= 'road-base'	)	;
%s5	(MM=coarse_aggregate_usage , F=f6, P= 'coarse_aggregate'	)	;
%s5	(MM=construction_sand_usage, F=f7, P= 'construction_sand'	)	;

data MM.Final_NRB;
set f1 f2 f3 f4 f5 f6 f7;
run;

proc datasets lib=work nolist;
delete f1 f2 f3 f4 f5 f6 f7;
quit;
run;



/*%s5(ot=ap_NRBACC	,	 MM=TO_PRED_A	,	 OO=PRED_NRBACCD_A	,	F=f31 , 	P='asphalt',	S='ACC')	;*/
/*%s5(ot=ap_NRBEDU	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBEDUD_A	,	F=f32 , 	P='asphalt',	S='EDU')	;*/
/*%s5(ot=ap_NRBENT	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBENTD_A	,	F=f33 , 	P='asphalt',	S='ENT')	;*/
/*%s5(ot=ap_NRBIND	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBINDD_A	,	F=f34 , 	P='asphalt',	S='IND')	;*/
/*%s5(ot=ap_NRBHEA	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBHEAD_A	,	F=f35 , 	P='asphalt',	S='HEA')	;*/
/*%s5(ot=ap_NRBOFF	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBOFFD_A	,	F=f36 , 	P='asphalt',	S='OFF')	;*/
/*%s5(ot=ap_NRBCOT	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBCOTD_A	,	F=f37 , 	P='asphalt',	S='COT')	;*/
/*%s5(ot=ap_NRBREL	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBRELD_A	,	F=f38 , 	P='asphalt',	S='REL')	;*/
/*%s5(ot=ap_NRBCOM	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBCOMD_A	,	F=f39 , 	P='asphalt',	S='COM')	;*/
/*%s5(ot=ap_NRBSOC	,	 MM=TO_PRED_A 	,	 OO=PRED_NRBSOCD_A	,	F=f40 , 	P='asphalt',	S='SOC')	;*/
/*%s5(ot=ap_NRBACC	,	 MM=TO_PRED_RB	,	 OO=PRED_NRBACC_RB	,	F=f41 , 	P='road-base',	S='ACC')	;*/
/*%s5(ot=ap_NRBEDU	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBEDU_RB	,	F=f42 , 	P='road-base',	S='EDU')	;*/
/*%s5(ot=ap_NRBENT	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBENT_RB	,	F=f43 , 	P='road-base',	S='ENT')	;*/
/*%s5(ot=ap_NRBIND	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBIND_RB	,	F=f44 , 	P='road-base',	S='IND')	;*/
/*%s5(ot=ap_NRBHEA	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBHEA_RB	,	F=f45 , 	P='road-base',	S='HEA')	;*/
/*%s5(ot=ap_NRBOFF	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBOFF_RB	,	F=f46 , 	P='road-base',	S='OFF')	;*/
/*%s5(ot=ap_NRBCOT	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBCOT_RB	,	F=f47 , 	P='road-base',	S='COT')	;*/
/*%s5(ot=ap_NRBREL	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBREL_RB	,	F=f48 , 	P='road-base',	S='REL')	;*/
/*%s5(ot=ap_NRBCOM	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBCOM_RB	,	F=f49 , 	P='road-base',	S='COM')	;*/
/*%s5(ot=ap_NRBSOC	,	 MM=TO_PRED_RB 	,	 OO=PRED_NRBSOC_RB	,	F=f50 , 	P='road-base',	S='SOC')	;*/