libname data 'C:\Users\Public\Documents';
libname pg odbc dsn="PostgreSQL30";


PROC SQL;
   CREATE TABLE DATA.n1 AS 
   SELECT t1.quarter_date as x1, 
          t1.sales_territory_name as x2, 
          t1.value_of_work_done as x3, 
/*          t1.hod_avg_floor_area as x4, */
          t1.TO_PRED_PMC as y
      FROM WORK.AP_NRBACC t1
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
          t2.premixed_concrete_usage
      FROM DATA.REF t1, WORK.AP_NRBACC t2
      WHERE (t1.x1 = t2.quarter_date AND t1.x2 = t2.sales_territory_name);
QUIT;

%macro grnn_learn(data = , x = , y = , sigma = , nn_out = );
options mprint mlogic nocenter;
********************************************************;
* THIS MACRO IS TO TRAIN A GENERAL REGRESSION NEURAL   *;
* NETWORK (SPECHT, 1991) AND STORE THE SPECIFICATION   *;
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
*  WENSUI.LIU@53.COM                                   *;
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