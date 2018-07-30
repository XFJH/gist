-- 查询当前模型跟跟踪表之间字段数目相异表
select md.owner, md.table_name, md.amount, tk.owner, tk.table_name, tk.amount from  
    (select t.owner, t.table_name, count(*) amount from dba_col_comments t
      where t.owner like 'BUF%'
      GROUP BY T.OWNER, T.TABLE_NAME
    ) md
  full join 
    (SELECT D.APP_NAME owner, D.TAB_NAME table_name, COUNT(*) amount FROM T_TRACK_TABLE D
      WHERE D.APP_NAME LIKE 'BUF%'
            and d.col_order != -1
            and d.is_valid = 0
      GROUP BY D.APP_NAME, D.TAB_NAME
    ) tk
  on md.owner = tk.owner
     and md.table_name = tk.table_name
     and md.amount = tk.amount
  where md.amount is null or tk.amount is null
;
