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
            (case when segement  ne "" then 'Low Rise Housing' else '' end) AS 'Market Segment'n
      FROM MM.F_LRH
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

data MM.Final_LRH;
set f1 f2 f3 f4 f5 f6 f7;
run;

proc datasets lib=work nolist;
delete f1 f2 f3 f4 f5 f6 f7;
quit;
run;