********************************************************;
* THIS MODEL IS TO TRAIN A GENERAL REGRESSION NEURAL   *;
* NETWORK  AND STORE THE SPECIFICATION   *;
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

libname data 'C:\Users\Public\Documents';
libname pg odbc dsn="PostgreSQL30";
PROC SQL;
   CREATE TABLE DATA.n1 AS 
   SELECT t1.quarter_date as x1, 
          t1.sales_territory_name as x2, 
          t1.hoh_value_of_work_done as x3, 
/*          t1.hod_avg_floor_area as x4, */
          t1.TO_PRED_CS as y
      FROM WORK.APPEND_HRH t1
      ORDER BY t1.sales_territory_name,
               t1.quarter_date;
QUIT;


/*PROC SQL;*/
/*   CREATE TABLE WORK.PRODUCT_USAGE AS */
/*   SELECT **/
/*      FROM PG.PRODUCT_USAGE t1;*/
/*QUIT;*/

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
          t2.construction_sand_usage
      FROM DATA.REF t1, WORK.APPEND_HRH t2
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t2.sales_territory_name);
QUIT;

%macro grnn_learn(data = , x = , y = , sigma = , nn_out = );
options mprint mlogic nocenter;

 
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
   CREATE TABLE WORK.check_csd AS 
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
		  t2.construction_sand_usage
      FROM WORK.map_pred_actual t1, work.REF2 t2
      WHERE (t1.x1 = t2.x1id AND t1.x2 = t2.x2id);
QUIT;
libname data 'C:\Users\Public\Documents';
libname pg odbc dsn="PostgreSQL30";
PROC SQL;
   CREATE TABLE DATA.n1 AS 
   SELECT t1.quarter_date as x1, 
          t1.sales_territory_name as x2, 
          t1.hoh_value_of_work_done as x3, 
/*          t1.hod_avg_floor_area as x4, */
          t1.TO_PRED_CA as y
      FROM WORK.APPEND_HRH t1
      ORDER BY t1.sales_territory_name,
               t1.quarter_date;
QUIT;


/*PROC SQL;*/
/*   CREATE TABLE WORK.PRODUCT_USAGE AS */
/*   SELECT **/
/*      FROM PG.PRODUCT_USAGE t1;*/
/*QUIT;*/

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
          t2.coarse_aggregate_usage
      FROM DATA.REF t1, WORK.APPEND_HRH t2
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t2.sales_territory_name);
QUIT;

%macro grnn_learn(data = , x = , y = , sigma = , nn_out = );
options mprint mlogic nocenter;

 
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
   CREATE TABLE WORK.check_cagg AS 
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
		  t2.coarse_aggregate_usage
      FROM WORK.map_pred_actual t1, work.REF2 t2
      WHERE (t1.x1 = t2.x1id AND t1.x2 = t2.x2id);
QUIT;
libname data 'C:\Users\Public\Documents';
libname pg odbc dsn="PostgreSQL30";
PROC SQL;
   CREATE TABLE DATA.n1 AS 
   SELECT t1.quarter_date as x1, 
          t1.sales_territory_name as x2, 
          t1.hoh_value_of_work_done as x3, 
/*          t1.hod_avg_floor_area as x4, */
          t1.TO_PRED_RB as y
      FROM WORK.APPEND_HRH t1
      ORDER BY t1.sales_territory_name,
               t1.quarter_date;
QUIT;


/*PROC SQL;*/
/*   CREATE TABLE WORK.PRODUCT_USAGE AS */
/*   SELECT **/
/*      FROM PG.PRODUCT_USAGE t1;*/
/*QUIT;*/

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
          t2.road_base_usage
      FROM DATA.REF t1, WORK.APPEND_HRH t2
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t2.sales_territory_name);
QUIT;

%macro grnn_learn(data = , x = , y = , sigma = , nn_out = );
options mprint mlogic nocenter;

 
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
   CREATE TABLE WORK.check_rb AS 
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
		  t2.road_base_usage
      FROM WORK.map_pred_actual t1, work.REF2 t2
      WHERE (t1.x1 = t2.x1id AND t1.x2 = t2.x2id);
QUIT;
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
QUIT;/*%s5	(MM=premixed_concrete_usage, F=f1, P= 'premixed_concrete' )	; */
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
          t1.TO_PRED_C as y
      FROM WORK.APPEND_HRH t1
      ORDER BY t1.sales_territory_name,
               t1.quarter_date;
QUIT;



/*PROC SQL;*/
/*   CREATE TABLE WORK.PRODUCT_USAGE AS */
/*   SELECT **/
/*      FROM PG.PRODUCT_USAGE t1;*/
/*QUIT;*/

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
          t2.cement_usage
      FROM DATA.REF t1, WORK.APPEND_HRH t2
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t2.sales_territory_name);
QUIT;

%macro grnn_learn(data = , x = , y = , sigma = , nn_out = );
options mprint mlogic nocenter;

 
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
   CREATE TABLE WORK.check_cem AS 
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
		  t2.cement_usage
      FROM WORK.map_pred_actual t1, work.REF2 t2
      WHERE (t1.x1 = t2.x1id AND t1.x2 = t2.x2id);
QUIT;/*%s5	(MM=premixed_concrete_usage, F=f1, P= 'premixed_concrete' )	; */
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
          t1.TO_PRED_PCC as y
      FROM WORK.APPEND_HRH t1
      ORDER BY t1.sales_territory_name,
               t1.quarter_date;
QUIT;



/*PROC SQL;*/
/*   CREATE TABLE WORK.PRODUCT_USAGE AS */
/*   SELECT **/
/*      FROM PG.PRODUCT_USAGE t1;*/
/*QUIT;*/

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
          t2.precast_concrete_usage
      FROM DATA.REF t1, WORK.APPEND_HRH t2
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t2.sales_territory_name);
QUIT;

%macro grnn_learn(data = , x = , y = , sigma = , nn_out = );
options mprint mlogic nocenter;
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
   CREATE TABLE WORK.check_pcc AS 
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
		  t2.precast_concrete_usage
      FROM WORK.map_pred_actual t1, work.REF2 t2
      WHERE (t1.x1 = t2.x1id AND t1.x2 = t2.x2id);
QUIT;
libname data 'C:\Users\Public\Documents';
libname pg odbc dsn="PostgreSQL30";
PROC SQL;
   CREATE TABLE DATA.n1 AS 
   SELECT t1.quarter_date as x1, 
          t1.sales_territory_name as x2, 
          t1.hoh_value_of_work_done as x3, 
/*          t1.hod_avg_floor_area as x4, */
          t1.TO_PRED_PMC as y
      FROM WORK.APPEND_HRH t1
      ORDER BY t1.sales_territory_name,
               t1.quarter_date;
QUIT;


/**/
/*PROC SQL;*/
/*   CREATE TABLE WORK.PRODUCT_USAGE AS */
/*   SELECT **/
/*      FROM PG.PRODUCT_USAGE t1;*/
/*QUIT;*/

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
          t2.premixed_concrete_usage
      FROM DATA.REF t1, WORK.APPEND_HRH t2
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t2.sales_territory_name);
QUIT;

%macro grnn_learn(data = , x = , y = , sigma = , nn_out = );
options mprint mlogic nocenter;

 
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
   CREATE TABLE WORK.check_pmc AS 
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
		  t2.premixed_concrete_usage
      FROM WORK.map_pred_actual t1, work.REF2 t2
      WHERE (t1.x1 = t2.x1id AND t1.x2 = t2.x2id);
QUIT;
ODS GRAPHICS ON;
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

/*==============ML = LRH===============*/
ODS GRAPHICS ON;
%macro s5(MM=, OO=, F=, P=);
PROC SORT
	DATA=WORK.APPEND_LRH(KEEP=quarter_date
	precast_concrete_usage cement_usage asphalt_usage road_base_usage coarse_aggregate_usage
    construction_sand_usage premixed_concrete_usage TO_PRED_PMC TO_PRED_PCC TO_PRED_C TO_PRED_A TO_PRED_RB TO_PRED_CA TO_PRED_CS
	hol_value_of_work_done use sales_territory_name)
	OUT=WORK.SORTTEMP
	;
	BY sales_territory_name use;
RUN;

PROC AUTOREG DATA = WORK.SORTTEMP 	
		PLOTS(ONLY)=(FITPLOT )
;
	class sales_territory_name;
	MODEL &MM = quarter_date hol_value_of_work_done/
	METHOD=ML
	MAXITER=50
	NLAG=1
		DW=1
	;
	
	OUTPUT OUT=MM.&OO.(LABEL="Forecasts for WORK.APPEND_LRH")

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
segement='LRH';
product=&P;
run; 
%mend s5;
%s5	(	 OO=PRED_LRHPMC 	,	 MM=TO_PRED_PMC, F=f1, P= 'premixed_concrete' )	; 
%s5	(	 OO=PRED_LRHPCC 	,	 MM=TO_PRED_PCC, F=f2, P= 'precast_concrete' )	;
%s5	(	 OO=PRED_LRH_CM 	,	 MM=TO_PRED_C, F=f3, P= 'cement' 	)	;
%s5	(	 OO=PRED_LRH_AG 	,	 MM=TO_PRED_A, F=f4, P= 'asphalt' 	)	;
%s5	(	 OO=PRED_LRHRB 	,	 MM=TO_PRED_RB, F=f5, P= 'road-base'	)	;
%s5	(	 OO=PRED_LRHCA 	,	 MM=TO_PRED_CA , F=f6, P= 'coarse_aggregate'	)	;
%s5	(	 OO=PRED_LRHCS 	,	 MM=TO_PRED_CS, F=f7, P= 'construction_sand'	)	;

ODS GRAPHICS OFF;


data MM.F_LRH;
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
            (case when segement  ne "" then 'Housing Alterations' else '' end) AS 'Market Segment'n
      FROM MM.F_HA
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

data MM.Final_HA;
set f1 f2 f3 f4 f5 f6 f7;
run;

proc datasets lib=work nolist;
delete f1 f2 f3 f4 f5 f6 f7;
quit;
run;
ODS GRAPHICS ON;
%macro s5(MM=, OO=, F=, P=);
PROC SORT
	DATA=WORK.APPEND_HA(KEEP=quarter_date
	precast_concrete_usage cement_usage asphalt_usage road_base_usage coarse_aggregate_usage
    construction_sand_usage premixed_concrete_usage TO_PRED_PMC TO_PRED_PCC TO_PRED_C TO_PRED_A TO_PRED_RB TO_PRED_CA TO_PRED_CS hoa_value_of_work_done use sales_territory_name)
	OUT=WORK.SORTTEMP
	;
	BY sales_territory_name use;
RUN;

PROC AUTOREG DATA = WORK.SORTTEMP 	
		PLOTS(ONLY)=(FITPLOT )
;
	BY sales_territory_name;
	MODEL &MM = quarter_date hoa_value_of_work_done/
	METHOD=ML
	MAXITER=50
	nlag=(2 4 8 12) backstep

	;
	
	OUTPUT OUT=MM.&OO.(LABEL="Forecasts for WORK.APPEND_HA")

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
segement='HA';
product=&P;
run; 
%mend s5;
%s5	(	 OO=PRED_HAPMC 	,	 MM=TO_PRED_PMC, F=f1, P= 'premixed_concrete' )	; 
%s5	(	 OO=PRED_HAPCC 	,	 MM=TO_PRED_PCC, F=f2, P= 'precast_concrete' )	;
%s5	(	 OO=PRED_HA_CM 	,	 MM=TO_PRED_C, F=f3, P= 'cement' 	)	;
%s5	(	 OO=PRED_HA_AG 	,	 MM=TO_PRED_A, F=f4, P= 'asphalt' 	)	;
%s5	(	 OO=PRED_HARB 	,	 MM=TO_PRED_RB, F=f5, P= 'road-base'	)	;
%s5	(	 OO=PRED_HACA 	,	 MM=TO_PRED_CA , F=f6, P= 'coarse_aggregate'	)	;
%s5	(	 OO=PRED_HACS 	,	 MM=TO_PRED_CS, F=f7, P= 'construction_sand'	)	;

ODS GRAPHICS OFF;


data MM.F_HA;
set f1 f2 f3 f4 f5 f6 f7;
run;

proc datasets lib=work nolist;
delete SORTTEMP f1 f2 f3 f4 f5 f6 f7;
quit;
run;
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
            (case when segement  ne "" then 'Detached Houses' else '' end) AS 'Market Segment'n
      FROM MM.F_DH
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

data MM.Final_DH;
set f1 f2 f3 f4 f5 f6 f7;
run;

proc datasets lib=work nolist;
delete f1 f2 f3 f4 f5 f6 f7;
quit;
run;

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





