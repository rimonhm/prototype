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
   CREATE TABLE WORK.check AS 
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

/*TO RE_RUN*/

proc datasets lib=work nolist;
delete data5 data6 data7 data8;
quit;
run;