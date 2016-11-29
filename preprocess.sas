libname pg odbc dsn="PostgreSQL30";
libname mm 'C:\Users\ronyr\Documents\sas_data';

%macro s1(ot=, SN=);
PROC SQL;
   CREATE TABLE WORK.&ot. AS 
   SELECT t1.* ,
          t2.use
      FROM PG.&SN. t1
           INNER JOIN MM.MOD t2 ON (t1.quarter_month = t2.QM);
QUIT;
%mend s1;
%s1(ot=DH, SN=DETACHED_HOUSING_IO) ;
%s1(ot=HRH, SN=HIGH_RISE_HOUSING_IO) ;
%s1(ot=HA, SN=HOUSING_ALTERATIONS_IO) ;
%s1(ot=LRH, SN=LOW_RISE_HOUSING_IO) ;
%s1(ot=NRB, SN=NON_RESIDENTIAL_BUILDING_IO) ;
%s1(ot=SDH, SN=SEMI_DETACHED_HOUSING_IO) ;

/*===============================================================================================*/

%macro s2(ot=, pt=, DN=);
PROC SQL;
   CREATE TABLE WORK.&ot. AS 
   SELECT t1.* ,
          /* TO_PRED */
            (t1.premixed_concrete_usage) AS TO_PRED_PMC,
			(t1.precast_concrete_usage) AS TO_PRED_PCC,
			(t1.cement_usage) AS TO_PRED_C,
			(t1.asphalt_usage) AS TO_PRED_A,
			(t1.road_base_usage) AS TO_PRED_RB,
			(t1.coarse_aggregate_usage) AS TO_PRED_CA,
			(t1.construction_sand_usage) AS TO_PRED_CS
      FROM WORK.&DN. t1
      WHERE t1.quarter_date <= '1Jun2016'd;
QUIT;
PROC SQL;
   CREATE TABLE WORK.&pt. AS 
   SELECT t1.* ,
          /* TO_PRED */
            (case when t1.premixed_concrete_usage >= 0 then . else t1.premixed_concrete_usage end) AS TO_PRED_PMC,
			(case when t1.precast_concrete_usage >= 0 then . else t1.premixed_concrete_usage end) AS TO_PRED_PCC,
			(case when t1.cement_usage >= 0 then . else t1.premixed_concrete_usage end) AS TO_PRED_C,
			(case when t1.asphalt_usage >= 0 then . else t1.premixed_concrete_usage end) AS TO_PRED_A,
			(case when t1.road_base_usage >= 0 then . else t1.premixed_concrete_usage end) AS TO_PRED_RB,
			(case when t1.coarse_aggregate_usage >= 0 then . else t1.premixed_concrete_usage end) AS TO_PRED_CA,
			(case when t1.construction_sand_usage >= 0 then . else t1.premixed_concrete_usage end) AS TO_PRED_CS

      FROM WORK.&DN. t1
      WHERE t1.quarter_date > '1Jun2016'd and t1.quarter_date <= '01Dec2019'd;
QUIT;
%mend s2;
%s2(ot=TRDH, pt=TSTDH , DN=DH) ;
%s2(ot=TRHRH, pt=TSTHRH , DN=HRH) ;
%s2(ot=TRHA, pt=TSTHA , DN=HA) ;
%s2(ot=TRLRH, pt=TSTLRH , DN=LRH) ;
%s2(ot=TRNRB, pt=TSTRB , DN=NRB) ;
%s2(ot=TRSDH, pt=TSTSDH , DN=SDH) ;



/*append*/
%macro s3(ot=, pt=, DN=);
PROC SQL;
CREATE TABLE WORK.&ot. AS 
SELECT * FROM WORK.&DN.
 OUTER UNION CORR 
SELECT * FROM WORK.&pt.
;
Quit;
%mend s3;
%s3(ot=APPEND_DH, pt=TSTDH , DN=TRDH) ;
%s3(ot=APPEND_HRH, pt=TSTHRH , DN=TRHRH) ;
%s3(ot=APPEND_HA, pt=TSTHA , DN=TRHA) ;
%s3(ot=APPEND_LRH, pt=TSTLRH , DN=TRLRH) ;
%s3(ot=APPEND_NRB, pt=TSTRB , DN=TRNRB) ;
%s3(ot=APPEND_SDH, pt=TSTSDH , DN=TRSDH) ;



/*NRB split*/

%macro s4(ot=, SN=);
PROC SQL;
   CREATE TABLE WORK.&ot. AS 
   SELECT *
      FROM APPEND_NRB
      where market_segment_name=&SN;
QUIT;
%mend s4;
%s4(ot=ap_NRBACC, SN='ACCOMMODATION') ;
%s4(ot=ap_NRBEDU, SN='EDUCATION') ;
%s4(ot=ap_NRBENT, SN='ENTERTAINMENT') ;
%s4(ot=ap_NRBIND, SN='FACTORY') ;
%s4(ot=ap_NRBHEA, SN='HEALTH') ;
%s4(ot=ap_NRBOFF, SN='OFFICE') ;
%s4(ot=ap_NRBCOT, SN='OTHER BUSINESS PREMISES') ;
%s4(ot=ap_NRBREL, SN='RELIGION') ;
%s4(ot=ap_NRBCOM, SN='RETAIL') ;
%s4(ot=ap_NRBSOC, SN='SOCIAL/OTHER') ;

/*=============ref============*/

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





