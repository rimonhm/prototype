/*%s5	(MM=premixed_concrete_usage, F=f1, P= 'premixed_concrete' )	; */
/*%s5	(MM=precast_concrete_usage, F=f2, P= 'precast_concrete' )	;*/
/*%s5	(MM=cement_usage, F=f3, P= 'cement' 	)	;*/
/*%s5	(MM=asphalt_usage, F=f4, P= 'asphalt' 	)	;*/
/*%s5	(MM=road_base_usage, F=f5, P= 'road-base'	)	;*/
/*%s5	(MM=coarse_aggregate_usage , F=f6, P= 'coarse_aggregate'	)	;*/
/*%s5	(MM=construction_sand_usage, F=f7, P= 'construction_sand'	)	;*/
/*%s5	(	 OO=PRED_HRHPMC_I 	,	 MM=TO_PRED_PMC, F=f1, P= 'premixed_concrete' )	; */
/*%s5	(	 OO=PRED_HRHPCC_I 	,	 MM=TO_PRED_PCC, F=f2, P= 'precast_concrete' )	;*/
/*%s5	(	 OO=PRED_HRH_CM_I 	,	 MM=TO_PRED_C, F=f3, P= 'cement' 	)	;*/
/*%s5	(	 OO=PRED_HRH_AG_I 	,	 MM=TO_PRED_A, F=f4, P= 'asphalt' 	)	;*/
/*%s5	(	 OO=PRED_HRHRB_I 	,	 MM=TO_PRED_RB, F=f5, P= 'road_base'	)	;*/
/*%s5	(	 OO=PRED_HRHCA_I 	,	 MM=TO_PRED_CA , F=f6, P= 'coarse_aggregate'	)	;*/
/*%s5	(	 OO=PRED_HRHCS_I 	,	 MM=TO_PRED_CS, F=f7, P= 'construction_sand'	)	;*/

libname data 'C:\Users\Public\Documents';
libname pg odbc dsn="PostgreSQL30";
PROC SQL;
   CREATE TABLE DATA.n1 AS 
   SELECT t1.quarter_date as x1, 
          t1.sales_territory_name as x2, 
          t1.hoh_value_of_work_done as x3, 
/*          t1.hod_avg_floor_area as x4, */
          t1.TO_PRED_A as y
      FROM WORK.APPEND_HRH t1
      ORDER BY t1.sales_territory_name,
               t1.quarter_date;
QUIT;



PROC SQL;
   CREATE TABLE WORK.PRODUCT_USAGE AS 
   SELECT *
      FROM PG.PRODUCT_USAGE t1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.id AS 
   SELECT DISTINCT t1.quarter_date
      FROM WORK.PRODUCT_USAGE t1;
QUIT;

PROC SQL;
   CREATE TABLE WORK.id2 AS 
   SELECT DISTINCT t1.sales_territory_name
      FROM WORK.PRODUCT_USAGE t1;
QUIT;


DATA id;
  SET id;
      id = _N_;  
  RUN;

  DATA id2;
  SET id2;
      id = _N_;  
  RUN;



PROC SQL;
   CREATE TABLE DATA.n2 AS 
   SELECT t2.id AS x1, 
          t3.id AS x2, 
          t1.x3, 
          t1.y
      FROM DATA.n1 t1, WORK.ID t2, WORK.ID2 t3
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t3.sales_territory_name);
QUIT;


PROC SQL;
   CREATE TABLE DATA.ref AS 
   SELECT t2.id AS x1id, 
          t3.id AS x2id, 
          t1.x3, t1.x1, t1.x2,
          t1.y
      FROM DATA.n1 t1, WORK.ID t2, WORK.ID2 t3
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t3.sales_territory_name);
QUIT;




/*===============for checking =============*/



PROC SQL;
   CREATE TABLE WORK.REF2 AS 
   SELECT t1.x1id, 
          t1.x2id, 
          t1.x3, 
          t1.x1, 
          t1.x2, 
          t1.y, 
          t2.asphalt_usage
      FROM DATA.REF t1, WORK.APPEND_HRH t2
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t2.sales_territory_name);
QUIT;

%macro grnn_learn(data = , x = , y = , sigma = , nn_out = );
options mprint mlogic nocenter;
********************************************************;
* THIS MACRO IS TO TRAIN A GENERAL REGRESSION NEURAL   *;
* NETWORK AND STORE THE SPECIFICATION   *;
*------------------------------------------------------*;
* INPUT PARAMETERS:                                    *;
*  DATA  : INPUT SAS DATASET                           *;
*  X     : A LIST OF PREDICTORS IN THE NUMERIC FORMAT  *;
*  Y     : A RESPONSE VARIABLE IN THE NUMERIC FORMAT   *;
*  SIGMA : THE SMOOTH PARAMETER FOR GRNN               *;
*  NN_OUT: OUTPUT SAS DATASET CONTAINING THE GRNN      *;
*          SPECIFICATION                               *;
*------------------------------------------------------*;
* AUTHOR:                                              *;
*  RIMON RONY                                *;
********************************************************;
 
data _tmp1;
  set &data (keep = &x &y);
  where &y ~= .;
  array _x_ &x;
  _miss_ = 0;
  do _i_ = 1 to dim(_x_);
    if _x_[_i_] = . then _miss_ = 1; 
  end;
  if _miss_ = 0 then output;
run;
 
proc summary data = _tmp1;
  output out = _avg_ (drop = _type_ _freq_)
  mean(&x) = ;
run;
 
proc summary data = _tmp1;
  output out = _std_ (drop = _type_ _freq_)
  std(&x) = ;
run;
 
proc standard data = _tmp1 mean = 0 std = 1 out = _data_;
  var &x;
run;
 
data &nn_out (keep = _neuron_ _key_ _value_);
  set _last_ end = eof;
  _neuron_ + 1;
  length _key_ $32;
  array _a_ &y &x;
  do _i_ = 1 to dim(_a_);
    if _i_ = 1 then _key_ = '_Y_';
    else _key_ = upcase(vname(_a_[_i_]));
    _value_ = _a_[_i_];
    output;
  end; 
  if eof then do;
    _neuron_ = 0;
    _key_  = "_SIGMA_";
    _value_  = &sigma;
    output;
    set _avg_;
    array _b_ &x;
    do _i_ = 1 to dim(_b_);
      _neuron_ = -1;
      _key_ = upcase(vname(_b_[_i_]));
      _value_ = _b_[_i_];
      output;
    end;
    set _std_;
    array _c_ &x;
    do _i_ = 1 to dim(_c_);
      _neuron_ = -2;
      _key_ = upcase(vname(_c_[_i_]));
      _value_ = _c_[_i_];
      output;
    end;
  end;
run;
 
proc datasets library = work;
  delete _: / memtype = data;
run;
quit;
 
********************************************************;
*              END OF THE MACRO                        *;
********************************************************;
%mend grnn_learn;





%grnn_learn(data = data.n2, x = x1 - x3, y = y, sigma = 0.8, nn_out = data.grnn);
 
proc print data = data.grnn (obs = 10) noobs;
run;


%macro grnn_pred(data = , x = , id = NA, nn_in = , out = grnn_pred);
options mprint mlogic nocenter;
********************************************************;
* THIS MACRO IS TO GENERATE PREDICTED VALUES BASED ON  *;
* THE SPECIFICATION OF GRNN CREATED BY THE %GRNN_LEARN *;
* MACRO                                                *;
*------------------------------------------------------*;
* INPUT PARAMETERS:                                    *;
*  DATA : INPUT SAS DATASET                            *;
*  X    : A LIST OF PREDICTORS IN THE NUMERIC FORMAT   *;
*  ID   : AN ID VARIABLE (OPTIONAL)                    *;
*  NN_IN: INPUT SAS DATASET CONTAINING THE GRNN        *;
*         SPECIFICATION GENERATED FROM %GRNN_LEARN     *;
*  OUT  : OUTPUT SAS DATASET WITH GRNN PREDICTIONS     *;
*------------------------------------------------------*;
* AUTHOR:                                              *;
*  WENSUI.LIU@53.COM                                   *;
********************************************************;
 
data data1;
  set &data;
  array _x_ &x;
  _miss_ = 0;
  do _i_ = 1 to dim(_x_);
    if _x_[_i_] = . then _miss_ = 1;
  end;
  if _miss_ = 0 then output;
run;
 
data data2;
  set data1 (drop = _miss_);
  %if &id = NA %then %do;
  _id_ + 1;
  %end;
  %else %do;
  _id_ = &id;
  %end;
run;
 
proc sort data = data2 sortsize = max nodupkey;
  by _id_;
run;
 
data data3 (keep = _id_ _key_ _value_);
  set data2;
  array _x_ &x;
  length _key_ $32;
  do _i_ = 1 to dim(_x_);
    _key_ = upcase(vname(_x_[_i_]));
    _value_ = _x_[_i_];
    output;
  end;
run;
 
proc sql noprint;
select _value_ ** 2 into :s2 from &nn_in where _neuron_ = 0;
 
create table
  data3 as 
select
  a._id_,
  a._key_,
  (a._value_ - b._value_) / c._value_ as _value_
from
  data3 as a,
  &nn_in as b,
  &nn_in as c
where
  compress(a._key_, ' ') = compress(b._key_, ' ') and
  compress(a._key_, ' ') = compress(c._key_, ' ') and
  b._neuron_ = -1                                 and
  c._neuron_ = -2;
 
create table
  data3 as
select
  a._id_,
  b._neuron_,
  sum((a._value_ - b._value_) ** 2) as d2,
  mean(c._value_)                   as y,
  exp(-(calculated d2) / (2 * &s2)) as exp
from
  data3  as a,
  &nn_in as b,
  &nn_in as c
where
  compress(a._key_, ' ') = compress(b._key_, ' ') and
  b._neuron_ = c._neuron_                         and
  b._neuron_ > 0                                  and
  c._key_ = '_Y_'
group by
  a._id_, b._neuron_;
 
create table
  data3 as
select
  a._id_,
  sum(a.y * a.exp / b.sum_exp) as _pred_
from
  data3 as a inner join (select _id_, sum(exp) as sum_exp from data3 group by _id_) as b
on
  a._id_ = b._id_
group by
  a._id_;
quit;
 
proc sort data = data3 out = &out sortsize = max;
  by _id_;
run;
 
********************************************************;
*              END OF THE MACRO                        *;
********************************************************;
%mend grnn_pred;

%grnn_pred(data = data.n2, x = x1 - x3, nn_in = data.grnn);


/*%grnn_pred(data = data.boston2, x = x1 - x13, nn_in = data.grnn);*/
proc print data = grnn_pred (obs = 10) noobs;
run;





PROC SQL;
   CREATE TABLE WORK.map_pred_actual AS 
   SELECT t1.x1, 
          t1.x2, 
          t1.x3, 
          t1.y, 
          t1._id_, 
          t2._pred_
      FROM WORK.data2 t1
           INNER JOIN WORK.grnn_pred t2 ON (t1._id_ = t2._id_);
QUIT;



PROC SQL;
   CREATE TABLE WORK.check_asp AS 
   SELECT t1.x1, 
          t1.x2, 
          t1.x3, 
          t1.y, 
          t1._id_, 
          t1._pred_, 
          t2.x1id, 
          t2.x2id, 
          t2.x3 AS x3a, 
          t2.x1 AS x1a, 
          t2.x2 AS x2a, 
          t2.y AS y1,
		  t2.asphalt_usage
      FROM WORK.map_pred_actual t1, work.REF2 t2
      WHERE (t1.x1 = t2.x1id AND t1.x2 = t2.x2id);
QUIT;
