ODS GRAPHICS ON;

%macro s5(MM=, OO=, F=, P=);
PROC SORT
	DATA=WORK.APPEND_DH(KEEP= premixed_concrete_usage quarter_date
	precast_concrete_usage cement_usage asphalt_usage road_base_usage coarse_aggregate_usage
    construction_sand_usage TO_PRED_PMC TO_PRED_PCC TO_PRED_C TO_PRED_A TO_PRED_RB TO_PRED_CA TO_PRED_CS hod_total_dwellings_approved hod_avg_floor_area 
	use sales_territory_name)
	OUT=WORK.SORTTEMP
	;
	BY sales_territory_name use;
RUN;

PROC AUTOREG DATA = WORK.SORTTEMP 	
		PLOTS(ONLY)=(FITPLOT )
;
	BY sales_territory_name;
	MODEL &MM = quarter_date hod_total_dwellings_approved hod_avg_floor_area/
	METHOD=ML 
	MAXITER=50
	nlag=(2 4 8 12) backstep
	;
	
	OUTPUT OUT=MM.&OO.(LABEL="Forecasts for WORK.APPEND_DH")

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
segement='DH';
product=&P;
run; 
%mend s5;
%s5	(	 OO=PRED_DHPMC 	,	 MM=TO_PRED_PMC, F=f1, P= 'premixed_concrete' )	; 
%s5	(	 OO=PRED_DHPCC 	,	 MM=TO_PRED_PCC, F=f2, P= 'precast_concrete' )	;
%s5	(	 OO=PRED_DH_CM 	,	 MM=TO_PRED_C, F=f3, P= 'cement' 	)	;
%s5	(	 OO=PRED_DH_AG 	,	 MM=TO_PRED_A, F=f4, P= 'asphalt' 	)	;
%s5	(	 OO=PRED_DHRB 	,	 MM=TO_PRED_RB, F=f5, P= 'road-base'	)	;
%s5	(	 OO=PRED_DHCA 	,	 MM=TO_PRED_CA , F=f6, P= 'coarse_aggregate'	)	;
%s5	(	 OO=PRED_DHCS 	,	 MM=TO_PRED_CS, F=f7, P= 'construction_sand'	)	;

ODS GRAPHICS OFF;


data MM.F_DH;
set f1 f2 f3 f4 f5 f6 f7;
run;

proc datasets lib=work nolist;
delete SORTTEMP f1 f2 f3 f4 f5 f6 f7;
quit;
run;

