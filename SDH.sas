

/*==============ML = SDH===============*/
ODS GRAPHICS ON;
%macro s5(MM=, OO=, F=, P=);
PROC SORT
	DATA=WORK.APPEND_SDH(KEEP=quarter_date
	precast_concrete_usage cement_usage asphalt_usage road_base_usage coarse_aggregate_usage
    construction_sand_usage premixed_concrete_usage TO_PRED_PMC TO_PRED_PCC TO_PRED_C TO_PRED_A TO_PRED_RB TO_PRED_CA TO_PRED_CS
    hos_one_storey_dwellings_approve hos_two_storey_dwellings_approve hos_avg_floor_area use sales_territory_name)
	OUT=WORK.SORTTEMP
	;
	BY sales_territory_name use;
RUN;

PROC AUTOREG DATA = WORK.SORTTEMP 	
		PLOTS(ONLY)=(FITPLOT )
;
	class sales_territory_name; 
	MODEL &MM = quarter_date hos_one_storey_dwellings_approve hos_two_storey_dwellings_approve hos_avg_floor_area/
	METHOD=ML
	MAXITER=50
	NLAG=1
		DW=1
	;
	
	OUTPUT OUT=MM.&OO.(LABEL="Forecasts for WORK.APPEND_SDH")

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
segement='SDH';
product=&P;
run; 
%mend s5;
%s5	(	 OO=PRED_SDHPMC 	,	 MM=TO_PRED_PMC, F=f1, P= 'premixed_concrete' )	; 
%s5	(	 OO=PRED_SDHPCC 	,	 MM=TO_PRED_PCC, F=f2, P= 'precast_concrete' )	;
%s5	(	 OO=PRED_SDH_CM 	,	 MM=TO_PRED_C, F=f3, P= 'cement' 	)	;
%s5	(	 OO=PRED_SDH_AG 	,	 MM=TO_PRED_A, F=f4, P= 'asphalt' 	)	;
%s5	(	 OO=PRED_SDHRB 	,	 MM=TO_PRED_RB, F=f5, P= 'road-base'	)	;
%s5	(	 OO=PRED_SDHCA 	,	 MM=TO_PRED_CA , F=f6, P= 'coarse_aggregate'	)	;
%s5	(	 OO=PRED_SDHCS 	,	 MM=TO_PRED_CS, F=f7, P= 'construction_sand'	)	;

ODS GRAPHICS OFF;


data MM.F_SDH;
set f1 f2 f3 f4 f5 f6 f7;
run;

proc datasets lib=work nolist;
delete SORTTEMP f1 f2 f3 f4 f5 f6 f7;
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
            (case when segement  ne "" then 'Semi Detached Houses' else '' end) AS 'Market Segment'n
      FROM MM.F_SDH
      WHERE product = &P;
QUIT;
%mend s5;
%s5	(MM=premixed_concrete_usage, F=f1, P= 'premixed_concrete' )	; 
%s5	(MM=precast_concrete_usage, F=f2, P= 'precast_concrete' )	;
%s5	(MM=cement_usage, F=f3, P= 'cement' 	)	;
%s5	(MM=asphalt_usage, F=f4, P= 'asphalt' 	)	;
%s5	(MM=road_base_usage, F=f5, P= 'road-base'	)	;
%s5	(MM=coarse_aggregate_usage , F=f6, P= 'coarse_aggregate'	)	;
%s5	(MM=construction_sand_usage, F=f7, P= 'construction_sand'	)	;

data MM.Final_SDH;
set f1 f2 f3 f4 f5 f6 f7;
run;

proc datasets lib=work nolist;
delete f1 f2 f3 f4 f5 f6 f7;
quit;
run;



