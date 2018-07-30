-- Create table
create table T_TRACK_TABLE
(
  sn               NUMBER,
  aaa              VARCHAR2(1000 CHAR),
  bbb              VARCHAR2(1000 CHAR),
  ccc              VARCHAR2(1000 CHAR),
  dd               VARCHAR2(1000 CHAR),
  ee               VARCHAR2(1000 CHAR),
  tab_name         VARCHAR2(1000 CHAR),
  app_name         VARCHAR2(1000 CHAR),
  col_order        NUMBER,
  is_valid         INTEGER default 0,
  add_batch_number NUMBER(10),
  add_date         DATE default sysdate,
  add_remark       VARCHAR2(4000 CHAR),
  del_batch_number NUMBER(10),
  del_date         DATE,
  del_remark       VARCHAR2(4000 CHAR),
  update_from_sn   NUMBER
);
-- Add comments to the columns 
comment on column T_TRACK_TABLE.sn
  is '流水号';
comment on column T_TRACK_TABLE.aaa
  is '中文名';
comment on column T_TRACK_TABLE.bbb
  is '字段名';
comment on column T_TRACK_TABLE.ccc
  is '数据类型';
comment on column T_TRACK_TABLE.dd
  is '是否非空';
comment on column T_TRACK_TABLE.ee
  is '是否主键';
comment on column T_TRACK_TABLE.tab_name
  is '表名';
comment on column T_TRACK_TABLE.app_name
  is '应用名';
comment on column T_TRACK_TABLE.col_order
  is '表内字段顺序';
comment on column T_TRACK_TABLE.is_valid
  is '是否有效，-1:已删除,失效；0:正在使用,有效。';
comment on column T_TRACK_TABLE.add_batch_number
  is '增加字段时的执行序号';
comment on column T_TRACK_TABLE.add_date
  is '添加日期';
comment on column T_TRACK_TABLE.add_remark
  is '添加时备注';
comment on column T_TRACK_TABLE.del_batch_number
  is '删除字段时的执行序号';
comment on column T_TRACK_TABLE.del_date
  is '删除日期';
comment on column T_TRACK_TABLE.del_remark
  is '删除时备注';
comment on column T_TRACK_TABLE.update_from_sn
  is '更新自哪个SN';

  
 

-- Create table
create global temporary table TMP_TRACK_TABLE
(
  sn               NUMBER,
  aaa              VARCHAR2(1000 CHAR),
  bbb              VARCHAR2(1000 CHAR),
  ccc              VARCHAR2(1000 CHAR),
  dd               VARCHAR2(1000 CHAR),
  ee               VARCHAR2(1000 CHAR),
  tab_name         VARCHAR2(1000 CHAR),
  app_name         VARCHAR2(1000 CHAR),
  col_order        NUMBER,
  is_valid         INTEGER default 0,
  add_batch_number NUMBER(10),
  add_date         DATE default sysdate,
  add_remark       VARCHAR2(4000 CHAR),
  del_batch_number NUMBER(10),
  del_date         DATE,
  del_remark       VARCHAR2(4000 CHAR),
  update_from_sn   NUMBER
)
on commit preserve rows;
-- Add comments to the table 
comment on table TMP_TRACK_TABLE
  is '用于存放跟踪表某一时刻的内容的临时表'; 

