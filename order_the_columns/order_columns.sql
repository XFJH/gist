DECLARE
   -- 字段顺序有问题的表
   CURSOR C1
   IS
   select distinct t.OWNER, t.table_name from dba_tab_columns t
    where T.OWNER LIKE 'BUF%'
          AND (T.TABLE_NAME LIKE 'C_%' OR T.TABLE_NAME LIKE 'T_%')
          AND t.TABLE_NAME not like 'TMP%'
          AND t.COLUMN_ID  > (
          select d.column_id from dba_tab_columns d
          where t.OWNER = d.OWNER
                and t.TABLE_NAME =d.TABLE_NAME
                and d.COLUMN_NAME = 'PROCESS_STATUS'
    );

   -- 查询指定表的主键, 返回主键名跟主键字段名们
   CURSOR C2(in_owner VARCHAR2, in_table_name VARCHAR2)
   IS
    select t.constraint_name
           , listagg(t.column_name, ',') within group ( order by t.position) column_names
           , listagg( ' t. ' || t.column_name || '=d.' || t.column_name , ' and ') within group ( order by t.position) conditons
    from (
      select t1.owner, t1.table_name, t1.constraint_name
            ,t2.column_name , t2.position
      from dba_constraints t1, dba_cons_columns t2
      where t1.owner = in_owner               -- 指定schema 
            AND t1.table_name = in_table_name -- 指定表名
            AND T1.constraint_type = 'P'
            AND t1.owner = t2.owner
            AND t1.table_name = t2.table_name
            AND t1.constraint_name = t2.constraint_name
      ) t
    group by t.owner, t.table_name, T.CONSTRAINT_NAME
    ;

   v_c1_record C1%ROWTYPE;
   v_c2_record C2%ROWTYPE;
   v_tab_order number := 1;
   v_sql varchar2(1000) := '';
   v_tmp_table_name VARCHAR2(1000) := NULL;
   v_tmp_pk_name VARCHAR2(1000) := null ;
   v_tmp_pk_columns VARCHAR2(1000)  := NULL;
   v_tmp_pk_conditions VARCHAR2(1000)  := NULL;
   v_columns_update VARCHAR2(1000) := NULL;
   v_regular_columns VARCHAR2(1000) := 'SOURCE_CODE,DATA_ORG_CODE,CREATE_DATE,CREATOR,LAST_UPDATE_DATE,UPDATE_BY,DELETE_FLAG,PROCESS_STATUS';

BEGIN

  FOR r_c1 IN C1
    LOOP
      DBMS_OUTPUT.put_line('-- ' || lpad(to_char(v_tab_order) , 2, ' ') || '.' ||  r_c1.owner || '.' || r_c1.table_name );

      -- 查询对应表的主键， 主键字段
      OPEN C2(r_c1.owner, r_c1.table_name) ;
        FETCH C2 INTO v_tmp_pk_name, v_tmp_pk_columns, v_tmp_pk_conditions;
        DBMS_OUTPUT.put_line('--  ' || v_tmp_pk_name || '---' || v_tmp_pk_columns );
      CLOSE C2;
      v_columns_update := v_tmp_pk_columns || ',' || v_regular_columns;
      
      -- 创建迁移表
      v_tmp_table_name := r_c1.owner || '.TMP_' || substr(r_c1.table_name, 6);
      v_sql := 'create table ' || v_tmp_table_name || ' as select * from '  || r_c1.owner || '.' || r_c1.table_name  || ' where 1 > 2'; 
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      
      
      -- 迁出规则字段与主键数据
      
      v_sql := 'insert into ' || v_tmp_table_name || '(' || v_columns_update
              || ') SELECT ' ||v_columns_update 
              || ' FROM ' || v_tmp_table_name;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql; 
      
      -- 删除后8位
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' drop column SOURCE_CODE';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' drop column DATA_ORG_CODE';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' drop column CREATE_DATE';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' drop column CREATOR';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' drop column LAST_UPDATE_DATE';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' drop column UPDATE_BY';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' drop column DELETE_FLAG';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' drop column PROCESS_STATUS';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      
      
      -- 增加字段(假设已经加上了需要加的字段，当删除8个规则字段后，需要加的字段自然已经在最末尾了， 所以指需要把删除的8个再追加回来即可）

      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' add  SOURCE_CODE VARCHAR2(30 CHAR) ';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql; 
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' add  DATA_ORG_CODE VARCHAR2(50 CHAR)';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql; 
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' add  CREATE_DATE DATE';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql; 
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' add  CREATOR VARCHAR2(50 CHAR)';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql; 
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' add  LAST_UPDATE_DATE DATE';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql; 
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' add  UPDATE_BY VARCHAR2(50 CHAR)';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;  
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' add  DELETE_FLAG CHAR(1 CHAR)';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql; 
      v_sql := 'alter table ' || r_c1.owner || '.' || r_c1.table_name || ' add  PROCESS_STATUS VARCHAR2(4 CHAR)';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;

      v_sql := 'COMMENT ON COLUMN ' || r_c1.owner || '.' ||  r_c1.table_name  || '.'  ||  'SOURCE_CODE IS '  ||  chr(39) || '源系统代码' || chr(39) ;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'COMMENT ON COLUMN ' || r_c1.owner || '.' ||  r_c1.table_name  || '.'  ||  'DATA_ORG_CODE IS '  ||  chr(39) || '数据来源' || chr(39) ;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'COMMENT ON COLUMN ' || r_c1.owner || '.' ||  r_c1.table_name  || '.'  ||  'CREATE_DATE IS '  ||  chr(39) || '创建日期' || chr(39) ;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'COMMENT ON COLUMN ' || r_c1.owner || '.' ||  r_c1.table_name  || '.'  ||  'CREATOR IS '  ||  chr(39) || '创建记录的用户或进程' || chr(39) ;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'COMMENT ON COLUMN ' || r_c1.owner || '.' ||  r_c1.table_name  || '.'  ||  'LAST_UPDATE_DATE IS '  ||  chr(39) || '最后更新日期' || chr(39) ;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'COMMENT ON COLUMN ' || r_c1.owner || '.' ||  r_c1.table_name  || '.'  ||  'UPDATE_BY IS '  ||  chr(39) || '最近更新的用户或进程' || chr(39) ;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'COMMENT ON COLUMN ' || r_c1.owner || '.' ||  r_c1.table_name  || '.'  ||  'DELETE_FLAG IS '  ||  chr(39) || '删除标志1是0否' || chr(39) ;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      v_sql := 'COMMENT ON COLUMN ' || r_c1.owner || '.' ||  r_c1.table_name  || '.'  ||  'PROCESS_STATUS IS '  ||  chr(39) || 'LANDING 到 共享库的同步状态' || chr(39) ;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      
      -- 更新数据
      v_sql := 'UPDATE ' || r_c1.owner || '.' || r_c1.table_name || ' d SET ( ' || v_regular_columns || ' ) '
              || ' = ( SELECT ' || v_regular_columns || ' FROM ' || v_tmp_table_name || ' t WHERE ' ||  v_tmp_pk_conditions || ')';
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;

      -- 删除迁移表
      v_sql := 'DROP TABLE ' || v_tmp_table_name;
      DBMS_OUTPUT.put_line(v_sql);
      EXECUTE IMMEDIATE v_sql;
      
      commit;
      
      v_tab_order := v_tab_order + 1;
    END LOOP;
    
END;