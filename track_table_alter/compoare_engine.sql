-- 后面合成的两个SQL执行会比较费时，大概300s左右
DECLARE
  CURSOR C1
  IS
  select owner, table_name, comments , t2.item_name_cn_short as app_name 
    from dba_tab_comments t1, cmx_dict.d_comm_msa_app t2
    where t1.owner like 'BUF%'
      --      AND t1.table_name in ('C_TH_DF_HANDLE', 'C_ZJ_NON_TAX_FEE_TEMP')
            AND(t1.table_name like 'C%' OR  t1.table_name LIKE 'T%')
            AND t1.table_name not like '%1'      --
            AND t1.table_name not like 'TMP%'    -- 临时表
            AND t1.table_name not like '%TEMP'   -- 临时表
            AND t1.table_name not like '%TEST'   -- 测试表
            AND t1.table_name not like '%TST'    -- 测试表
            AND t1.table_name not like '%BAK'    -- 备份表
            AND t1.owner not in ('BUF_THHJ2', 'BUF_4A', 'BUF_CBFW', 'BUF_CZKH', 'BUF_CBJY_CCS')  -- 不可用系统
            AND t1.table_name NOT LIKE '%0627'   -- 跑mdm ETL 备份表
            AND t1.table_name not like 'CMP%'    -- 未知
            AND t1.table_name not like 'BIN$%'   -- 回收站的表
          and t1.owner = t2.code
          and t1.owner like 'BUF%' --限定跟踪的表
          and t1.table_name not like 'DQREC%'
          order by t1.owner, t1.table_name ;
  
  -- 根据指定的schema名跟表名，返回表的定义以及注释
  CURSOR C2(compare_owner varchar2, compare_table_name varchar2)
  IS
  select t2.column_id, t1.table_name
        ,t1.comments    comments
        ,t1.column_name column_name
        ,decode(t2.data_type, 'DATE', 'DATE'
                             ,'CHAR',     'CHAR('     || t2.char_length || ')'
                             ,'VARCHAR2', 'VARCHAR2(' || t2.char_length || ')'
                             ,'NUMBER',   
                                 CASE
                                   WHEN t2.data_precision is null and t2.data_scale is null THEN 'NUMBER'
                                   ELSE 'NUMBER('   || t2.data_precision || ','  || t2.data_scale || ')'
                                 END
                             ,'FLOAT',    'FLOAT('    || t2.data_precision ||')'
                             ,'LONG',     'LONG'
                             ,'CLOB',     'CLOB'
                             ,'BLOB',     'BLOB'
                             ,'TIMESTAMP(6)', 'TIMESTAMP(6)'
                             ,'Error') data_type
        ,decode(t2.nullable,  'Y', 'F'
                             ,'N', 'T'
                             ,'Error') is_not_null
        ,case
            when t1.column_name in (select ucc.column_name from dba_constraints uc, dba_cons_columns ucc
                                 where UC.owner = UCC.owner
                                       and uc.table_name = ucc.table_name
                                       AND uc.CONSTRAINT_TYPE = 'P'
                                       and uc.constraint_name = ucc.constraint_name
                                       and uc.owner = t1.owner
                                       and uc.table_name = t1.table_name
                                 ) then 'T'
            else 'F' 
        end is_primary_key
        , t3.item_name_cn_short app_name
        , '' topic
  from dba_col_comments t1, (
    select column_id, owner, table_name, column_name, data_type, data_length, char_length,  data_precision, data_scale , nullable from dba_tab_columns
    where owner = compare_owner 
          and table_name = compare_table_name
    ) t2
    , cmx_dict.d_comm_msa_app t3
  where t1.owner = t2.owner and t2.owner = t3.code
        and t1.table_name = t2.table_name and t1.column_name = t2.column_name
  order by column_id ;
  
  c_c1_record C1%ROWTYPE;
  c_c2_record C2%ROWTYPE;
  sn number := 0;
  sn_tab number:= 0;
  s_sql varchar2(4000 char) := '';
  s_tab_name varchar2(1000 char) := '';
  s_tab_tmp  varchar2(1000 char) := 'TMP_TRACK_TABLE';
  s_tab_track_his varchar2(1000 char) := 'T_TRACK_TABLE'; 
  n_batch number := 0;  -- 执行批次号
  n_max_track number := 0;
BEGIN
  
  s_sql := 'delete from ' || s_tab_tmp ;
  execute immediate s_sql;
  commit;
  
  -- 为 n_batch 赋值
  s_sql := 'select greatest((case when max(add_batch_number) is null then 0 else max(add_batch_number) end) '
         ||'              , (case when max(del_batch_number) is null then 0 else max(del_batch_number) end) ) + 1 from ' || s_tab_track_his ;
 -- dbms_output.put_line(s_sql);
  execute immediate s_sql into n_batch;
  

    

  -- 生成当前表的结构并存储到 $s_tab_out
  OPEN C1;
  LOOP
    FETCH c1 INTO c_c1_record;
    IF c1%found THEN
      s_tab_name := replace(c_c1_record.comments, ' ', '') || c_c1_record.table_name || ':' ;
            
            
      sn_tab := sn_tab + 1;
  --    DBMS_OUTPUT.PUT_LINE( lpad(to_char(sn_tab), 3, ' ')  || '. ' ||  s_tab_name );
      
      -- 表名行
      sn := sn + 1;

      s_sql := 'INSERT INTO ' || s_tab_tmp || ' (sn, add_batch_number,  aaa, tab_name , col_order, app_name) values (' 
                     ||            sn                                           || ',' 
                     ||            n_batch                                  || ',' 
                     || chr(39) || s_tab_name                        || chr(39) || ',' 
                     || chr(39) || c_c1_record.table_name            || chr(39) || ', -1, '
                     || chr(39) || c_c1_record.owner                 || chr(39) || ')' ;
                     
  --    dbms_output.put_line(s_sql);
      execute immediate s_sql;     
      
      -- 标题行
      sn := sn + 1;
      s_sql := 'INSERT INTO ' || s_tab_tmp || ' (sn, add_batch_number,  aaa, bbb, ccc, dd, ee, tab_name, col_order, app_name ) values (' 
                     ||            sn                                || ',' 
                     ||            n_batch                           || ',' 
                     || chr(39) || '中文名'               || chr(39) || ',' 
                     || chr(39) || '字段名'               || chr(39) || ','
                     || chr(39) || '数据类型'             || chr(39) || ','
                     || chr(39) || '是否非空'             || chr(39) || ','
                     || chr(39) || '是否主键'             || chr(39) || ','
                     || chr(39) || c_c1_record.table_name || chr(39) || ', -1 ,'
                     || chr(39) || c_c1_record.owner      || chr(39) || ')' ;
  --    dbms_output.put_line(s_sql);
      execute immediate s_sql;
      
      
      OPEN C2(c_c1_record.owner, c_c1_record.table_name);
      LOOP
        FETCH C2 INTO c_c2_record;
        IF c2%found THEN
          
           -- 字段内容行
           sn := sn + 1;
           s_sql := 'INSERT INTO ' || s_tab_tmp || ' (sn, add_batch_number, aaa, bbb, ccc, dd, ee, tab_name, col_order, app_name ) values (' 
                     ||            sn                                         || ',' 
                     ||            n_batch                                    || ',' 
                     || chr(39) || c_c2_record.comments            || chr(39) || ',' 
                     || chr(39) || c_c2_record.column_name         || chr(39) || ','
                     || chr(39) || c_c2_record.data_type           || chr(39) || ','
                     || chr(39) || c_c2_record.is_not_null         || chr(39) || ','
                     || chr(39) || c_c2_record.is_primary_key      || chr(39) || ','
                     || chr(39) || c_c2_record.table_name          || chr(39) || ','
                     ||            c_c2_record.column_id                      || ','
                     || chr(39) || c_c1_record.owner               || chr(39) || ')' ;
      --     dbms_output.put_line(s_sql);
           execute immediate s_sql;
        ELSE
           EXIT;
        END IF;
      END LOOP;
      CLOSE C2;
    ELSE
      EXIT;
    END IF;
  END LOOP;
  CLOSE C1;
  
  COMMIT;
  
  -- 将新生成的表结构跟以前生成的结构进行比较，更新跟踪表(T_TRACK_TABLE)
  -- 在t_track_table 表中标记无效的记录
  s_sql :=   ' update ' || s_tab_track_his || ' t set t.is_valid = -1, t.del_date = sysdate , del_batch_number=' || n_batch  
          || ' where t.sn in (  '
            -- 查找被删除的记录 
          || '   select t.sn from ' || s_tab_track_his || ' t '
          || '   where t.is_valid = 0  '
          || '         and upper(t.aaa ||  t.bbb || t.ccc || t.dd ||  t.ee || t.tab_name || t.app_name) not in ( '
          || '      select upper(d.aaa ||  d.bbb || d.ccc || d.dd ||  d.ee || d.tab_name || d.app_name) from ' || s_tab_tmp || ' d ) '
          || ' )  ';
   dbms_output.put_line(s_sql);
   execute immediate s_sql;
   
   s_sql := 'select case when max(sn) is null then 0 else max(sn) end  from ' || s_tab_track_his ;
   execute immediate s_sql into n_max_track;
   
    --2-2. 添加
   s_sql :=  'insert into ' || s_tab_track_his || '(sn, add_batch_number, aaa, bbb, ccc, dd, ee, tab_name, app_name, col_order, is_valid, add_date)                                                '
          || ' select  ' || to_char(n_max_track) || ' + sn,  t.add_batch_number, t.aaa, t.bbb, t.ccc, t.dd, t.ee, t.tab_name, t.app_name, t.col_order, t.is_valid, t.add_date     '
          || '   from  ' || s_tab_tmp || ' t '
          || '  where      upper(t.aaa ||  t.bbb || t.ccc || t.dd ||  t.ee || t.tab_name || t.app_name) not in ( '
          || '      select upper(d.aaa ||  d.bbb || d.ccc || d.dd ||  d.ee || d.tab_name || d.app_name) from ' ||  s_tab_track_his || '  d ) '
          || ' order by    t.sn                   ';
  
   dbms_output.put_line(s_sql);
   execute immediate s_sql;
   
   commit;
   
END;
