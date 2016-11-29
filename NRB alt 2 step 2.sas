%grnn_learn(data = data.n2, x = x1 - x3, y = y, sigma = 0.17, nn_out = data.grnn);
 
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