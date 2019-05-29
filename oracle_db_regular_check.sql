set heading off
select '一、数据库的基本情况' from dual;

set heading off
select '1、数据库版本' from dual;
set heading on
select * from v$version;

set heading off
select '2、查看数据库基本信息' from dual;
set heading on
set linesize 500
col host_name for a20
select dbid,name,instance_name,instance_name,version,parallel rac,host_name from v$database,v$instance;


set heading off
select '3、实例状态' from dual;
set heading on
select instance_number,instance_name ,status from gv$instance;

set heading off
select '4、数据库运行时间' from dual;
set heading on
select to_char(startup_time, 'DD-MON-YYYY HH24:MI:SS') 启动时间,
       TRUNC(sysdate - (startup_time)) || '天 ' ||
       TRUNC(24 *
             ((sysdate - startup_time) - TRUNC(sysdate - startup_time))) ||
       '小时 ' || MOD(TRUNC(1440 * ((SYSDATE - startup_time) -
                          TRUNC(sysdate - startup_time))),
                    60) || '分 ' ||
       MOD(TRUNC(86400 *
                 ((SYSDATE - STARTUP_TIME) - TRUNC(SYSDATE - startup_time))),
           60) || '秒' 运行时间
  from v$instance;

set heading off
select '5、内存情况' from dual;
set heading on
select * from v$sgainfo;

set heading off
select '6、cpu情况' from dual;
set heading on
col STAT_NAME for a20
col COMMENTS for a50
Select stat_name,value,comments from v$osstat where stat_name in ('NUM_CPUS','IDLE_TIME','BUSY_TIME','USER_TIME','SYS_TIME','IOWAIT_TIME');

set heading off
select '二、检查Oracle对象状态' from  dual;


set heading off
select '1、查看参数文件位置' from dual;
show parameter spfile



set heading off
col NAME for a50
select '2、查看控制文件' from dual;
set heading on
select status,name from v$controlfile;


set heading off
select '3、查看在线日志' from dual;
set heading on
col MEMBER for a50
select group#,status,type,member from v$logfile;


set heading off
select '4、检查日志切换频率' from dual;
set heading on
select sequence#,
       to_char(first_time, 'yyyymmdd_hh24:mi:ss') firsttime,
       round((first_time - lag(first_time) over(order by first_time)) * 24 * 60,
             2) minutes
  from v$log_history
 where first_time > sysdate - 1
 order by first_time, minutes;

set heading off
select '5、查看数据文件' from dual;
set heading on
col NAME  for a50
select name,status from v$datafile;


set heading off
select '6、查看无效的对象' from dual;
set heading on
set linesize 500
select owner, object_name, object_type
  from dba_objects
 where status != 'VALID'
   and owner != 'SYS'
   and owner != 'SYSTEM';



set heading off
select '7、查看回滚段状态' from dual;
set heading on
select segment_name,status from dba_rollback_segs;


set heading off
select '8、检查是否有禁用约束' from dual;
set heading on
set linesize 1000
SELECT owner, constraint_name, table_name, constraint_type, status 
     FROM dba_constraints 
    WHERE status ='DISABLE' and constraint_type='P';


set heading off
select '9、检查是否有禁用触发器' from dual;
set heading on
col owner for a10
col taigger_name for a10
col table_name for a30
col table_name for a30
 SELECT owner, trigger_name, table_name, status FROM dba_triggers WHERE status = 'DISABLED';

set heading off
select '10、Oracle Job是否有失败' from dual;
set heading on
select job,what,last_date,next_date,failures,broken from dba_jobs Where schema_user='CAIKE';

set heading off
select '11、检查失效的索引' from dual;
set heading on
select index_name,table_name,tablespace_name,status From dba_indexes Where owner='CTAIS2' And status<>'VALID';


set heading off
select '三、检查Oracle相关资源的使用情况' from dual;


set heading off
select '1、查看表空间的使用情况' from dual;
set heading on
set linesize 1000
SELECT UPPER(F.TABLESPACE_NAME) "tablespace_name",
       D.TOT_GROOTTE_MB "tablesapce_size(M)",
       D.TOT_GROOTTE_MB - F.TOTAL_BYTES "used_tablespace_size(M)",
       TO_CHAR(ROUND((D.TOT_GROOTTE_MB - F.TOTAL_BYTES) / D.TOT_GROOTTE_MB * 100,
                     2),
               '990.99') "used%",
       F.TOTAL_BYTES "free_size(M)",
       F.MAX_BYTES "max_byte(M)"
  FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) TOTAL_BYTES,
               ROUND(MAX(BYTES) / (1024 * 1024), 2) MAX_BYTES
          FROM SYS.DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) F,
       (SELECT DD.TABLESPACE_NAME,
               ROUND(SUM(DD.BYTES) / (1024 * 1024), 2) TOT_GROOTTE_MB
          FROM SYS.DBA_DATA_FILES DD
         GROUP BY DD.TABLESPACE_NAME) D
 WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME
 ORDER BY 4 DESC;


set heading off
select '2、查看临时表空间使用情况' from dual;
set heading on
select tablespace_name , sum(bytes)/1024/1024 from dba_temp_files group by tablespace_name;

set heading off
select '3、查看临时段使用的情况' from dual;
set heading on
COL username FORMAT a10;
COL segtype FORMAT a10;
SELECT username,
       segtype,
       extents  "Extents Allocated",
       blocks   "Blocks Allocated"
  FROM v$tempseg_usage;


set heading off
select '4、查看所有数据文件i/o情况' from dual;
set heading on
SELECT ts.name      AS ts,
       fs.phyrds    "Reads",
       fs.phywrts   "Writes",
       fs.phyblkrd  AS br,
       fs.phyblkwrt AS bw,
       fs.readtim   "RTime",
       fs.writetim  "WTime"
  FROM v$tablespace ts, v$datafile df, v$filestat fs
 WHERE ts.ts# = df.ts#
   AND df.file# = fs.file#
UNION
SELECT ts.name      AS ts,
       ts.phyrds    "Reads",
       ts.phywrts   "Writes",
       ts.phyblkrd  AS br,
       ts.phyblkwrt AS bw,
       ts.readtim   "RTime",
       ts.writetim  "WTime"
  FROM v$tablespace ts, v$tempfile tf, v$tempstat ts
 WHERE ts.ts# = tf.ts#
   AND tf.file# = ts.file#
 ORDER BY 1;


set heading off
select '5、查看top 10 热segment' from dual;
set heading on
col objct_name for a30
col OWNER  for a20
select *
  from (select ob.owner, ob.object_name, sum(b.tch) Touchs
          from x$bh b, dba_objects ob
         where b.obj = ob.data_object_id
           and b.ts# > 0
         group by ob.owner, ob.object_name
         order by sum(tch) desc)
 where rownum <= 10;

set heading off
select '6、查看物理读最多的object' from dual;
set heading on
select *
  from (select owner, object_name, value
          from v$segment_statistics
         where statistic_name = 'physical reads'
         order by value desc)
 where rownum <= 10;


set heading off
select '7、查看热点数据文件(从单块读取时间判断)' from dual;
set heading on
SELECT t.file_name, 
          t.tablespace_name, 
          round(s.singleblkrdtim / s.singleblkrds, 2) AS CS,  
          s.READTIM, 
          s.WRITETIM 
     FROM v$filestat s, dba_data_files t 
    WHERE s.file# = t.file_id and rownum<=10 order by cs desc;


set heading off
select '8、检查Oracle初始化文件中相关参数值' from dual;
set heading on
select resource_name,max_utilization,initial_allocation,
    limit_value from v$resource_limit;
set heading off
select '注：若LIMIT_VALU - MAX_UTILIZATION<=5，则表明与RESOURCE_NAME相关的Oracle初始化参数需要调整。可以通过参数文件调整。' from dual;



set heading off
select '9、检查数据库连接情况' from dual;
set heading on
select sid,serial#,username,program,machine,status from v$session;
set heading off
select "(注：杀掉会话的语句alter system kill session 'SID,SERIAL#')" from dual;


set heading off
select '10、查看热点数据文件' from dual;
set heading on
SELECT t.file_name, 
          t.tablespace_name, 
          round(s.singleblkrdtim / s.singleblkrds, 2) AS CS,  
          s.READTIM, 
          s.WRITETIM 
     FROM v$filestat s, dba_data_files t 
    WHERE s.file# = t.file_id and rownum<=10 order by cs desc;
    
    
 
set heading off
select ' 11、检查一些扩展异常的对象 ' from dual;
set heading on

select Segment_Name, Segment_Type, TableSpace_Name, 
(Extents/Max_extents)*100 Percent 
From sys.DBA_Segments 
Where Max_Extents != 0 and (Extents/Max_extents)*100>=95 
order By Percent; 


set heading off
select ' 12、检查system表空间内的内容 ' from dual;
set heading on
select distinct(owner) from dba_tables 
where tablespace_name='SYSTEM' and 
owner!='SYS' and owner!='SYSTEM' 
union 
select distinct(owner) from dba_indexes 
where tablespace_name='SYSTEM' and
owner!='SYS' and owner!='SYSTEM';



set heading off
select ' 13、检查对象的下一扩展与表空间的最大扩展值 ' from dual;
set heading on
select a.table_name, a.next_extent, a.tablespace_name
  from all_tables a,
       (select tablespace_name, max(bytes) as big_chunk
          from dba_free_space
         group by tablespace_name) f
 where f.tablespace_name = a.tablespace_name
   and a.next_extent > f.big_chunk
union
select a.index_name, a.next_extent, a.tablespace_name
  from all_indexes a,
       (select tablespace_name, max(bytes) as big_chunk
          from dba_free_space
         group by tablespace_name) f
 where f.tablespace_name = a.tablespace_name
   and a.next_extent > f.big_chunk;

set heading off
select '四、内存的具体查看' from dual;

set heading off
select '  1、查看内存占用各个池子大小' from dual;
set heading on 
COL name FORMAT a32;
SELECT pool, name, bytes
  FROM v$sgastat
 WHERE pool IS NULL
    OR pool != 'shared pool'
    OR (pool = 'shared pool' AND
       (name IN ('dictionary cache',
                  'enqueue',
                  'library cache',
                  'parameters',
                  'processes',
                  'sessions',
                  'free memory')))
 ORDER BY pool DESC NULLS FIRST, name;


set heading off
select '  2、检查shered pool  free  space ' from dual;
set heading on 
SELECT * FROM V$SGASTAT
WHERE NAME = 'free memory'
  AND POOL = 'shared pool';


set heading off
select '  3、检查shared pool中library cach ' from dual;
set heading on 
select namespace,pinhitratio from v$librarycache;


set heading off
select '  4、检查整体命中率(library cache)' from dual;
set heading on 
 select sum(pins) "hits",
            sum(reloads) "misses",
            sum(pins)/(sum(pins)+sum(reloads)) "Hits Ratio"
    from v$librarycache;


set heading off
select '  5、library cache中详细比率信息' from dual;
set heading on
SELECT 'Library Lock Requests' "Ratio",
       ROUND(AVG(gethitratio) * 100, 2) || '%' "Percentage"
  FROM V$LIBRARYCACHE
UNION ALL
SELECT 'Library Pin Requests' "Ratio",
       ROUND(AVG(pinhitratio) * 100, 2) || '%' "Percentage"
  FROM V$LIBRARYCACHE
UNION ALL
SELECT 'Library I/O Reloads' "Ratio",
       ROUND((SUM(reloads) / SUM(pins)) * 100, 2) || '%' "Percentage"
  FROM V$LIBRARYCACHE
UNION ALL
SELECT 'Library Reparses' "Ratio",
       ROUND((SUM(reloads) / SUM(pins)) * 100, 2) || '%' "Percentage"
  FROM V$LIBRARYCACHE;


set heading off
select '  6、检查数据字典的命中率' from dual;
set heading on
SELECT (SUM(GETS - GETMISSES - FIXED)) / SUM(GETS) "ROW CACHE" FROM V$ROWCACHE;
set heading off
select '注：row cache的命中率至少小于90%' from dual;


set heading off
select '  7、每个子shared pool由 单独的shared pool latch保护 查看 他们的命中率 ' from dual;
set heading on
col name format a15
select addr,name,gets,misses,1-misses/gets from v$latch_children where name='shared pool';


set heading off
select ' 8、查看shared pool建议' from dual;
set heading on
column c1     heading 'Pool |Size(M)'
column c2     heading 'Size|Factor'
column c3     heading 'Est|LC(M)  '
column c4     heading 'Est LC|Mem. Obj.'
column c5     heading 'Est|Time|Saved|(sec)'
column c6     heading 'Est|Parse|Saved|Factor'
column c7     heading 'Est|Object Hits'   format 999,999,999
SELECT shared_pool_size_for_estimate c1,
       shared_pool_size_factor c2,
       estd_lc_size c3,
       estd_lc_memory_objects c4,
       estd_lc_time_saved c5,
       estd_lc_time_saved_factor c6,
       to_char(estd_lc_memory_object_hits, 99999999999) c7
  FROM V$SHARED_POOL_ADVICE;


set heading off
select ' 9、查看shared pool中 各种类型的chunk的大小数量' from dual;
set heading on
SELECT KSMCHCLS CLASS,
       COUNT(KSMCHCLS) NUM,
       SUM(KSMCHSIZ) SIZ,
       To_char(((SUM(KSMCHSIZ) / COUNT(KSMCHCLS) / 1024)), '999,999.00') || 'k' "AVG SIzE"
  FROM X$KSMSP
 GROUP BY KSMCHCLS;


set heading off
select ' 10、查看使用shard_pool保留池情况' from dual;
set heading on
SELECT request_misses, request_failures, free_space
FROM v$shared_pool_reserved;


set heading off
select '11、 pga 建议' from dual;
set heading on
SELECT (SELECT ROUND(value / 1024 / 1024, 0)
          FROM v$parameter
         WHERE name = 'pga_aggregate_target') "Current Mb",
       ROUND(pga_target_for_estimate / 1024 / 1024, 0) "Projected Mb",
       ROUND(estd_pga_cache_hit_percentage) "%"
  FROM v$pga_target_advice
 ORDER BY 2;


set heading off
select ' 12、查看buffer cache 命中率' from dual;
set heading on
select 1 - (sum(decode(name, 'physical reads', value, 0)) /
       (sum(decode(name, 'db block gets', value, 0)) +
       (sum(decode(name, 'consistent gets', value, 0))))) "Buffer Hit Ratio"
  from v$sysstat;


set heading off
select ' 13、查看buffer cache设置大小建议' from dual;
set heading on
select size_for_estimate,
       estd_physical_read_factor,
       to_char(estd_physical_reads, 99999999999999999999999) as"estd_physical_reads"
  from v$db_cache_advice
 where name = 'DEFAULT';


set heading off
select '14、查看buffer cache中defalut pool 命中率' from dual;
set heading on
select name,1-(physical_reads)/(consistent_gets+db_block_gets)
     from v$buffer_pool_statistics;
     set heading off
select '注：default池命中率至少要大于90%' from dual;

set heading off
select '15、检查lgwr i/o性能' from dual;
set heading on
select total_waits,time_waited,average_wait,time_waited/total_waits as avg from v$system_event where event = 'log file parallel write';


set heading off
select '16、检查与redo相关性能指标' from dual;
set heading on
set linesize 500
select name,value from v$sysstat where name like '%redo%';


set heading off
select ' 17、查询redo block size' from dual;
set heading on
select max(lebsz) from x$kccle;


set heading off
select '18、  计算出每个事务平均处理多少个redo block' from dual;
set heading on
select a.redoblocks / b.trancount
  from (select value redoblocks
          from v$sysstat
         where name = 'redo blocks written') a,
       (select value trancount from v$sysstat where name = 'user commits') b;


set heading off
select ' 19、 检查undo rollback segment 使用情况' from dual;
set heading on
column name for a60
select name, rssize, extents, latch, xacts, writes, gets, waits
  from v$rollstat a, v$rollname b
 where a.usn = b.usn
 order by waits desc;


set heading off
select '  20、计算每秒钟产生的undoblk数量' from dual;
set heading on
select sum(undoblks)/sum((end_time-begin_time)*24*60*60) from v$undostat; 


set heading off
select ' 21、查询undo具体信息' from dual;
set heading on
column undob FORMAT 99990;
column trans FORMAT 99990;
column snapshot2old FORMAT 9999999990;
SELECT undoblks       "UndoB",
       txncount       "Trans",
       maxquerylen    "LongestQuery",
       maxconcurrency "MaxConcurrency",
       ssolderrcnt    "Snapshot2Old",
       nospaceerrcnt  "FreeSpaceWait"
  FROM v$undostat;


set heading off
select ' 22、查询rollback 段详细信息(收缩次数,扩展次数,平均活动事务等)' from dual;
set heading on
column RBS FORMAT a50;
SELECT n.name      "RBS",
       s.extends   "Extends",
       s.shrinks   "Shrinks",
       s.wraps     "Wraps",
       s.aveshrink "AveShrink",
       s.aveactive "AveActive"
  FROM v$rollname n
  JOIN v$rollstat s
 USING (usn)
 WHERE n.name != 'SYSTEM';


set heading off
select ' 23、查询当前rollback segment使用情况' from dual;
set heading on
column RBS FORMAT a50;
SELECT n.name "RBS",
       s.status,
       s.waits,
       s.gets,
       to_char(s.writes, '9999999999999'),
       s.xacts "Active Trans"
  FROM v$rollname n
  JOIN v$rollstat s
 USING (usn)
 WHERE n.name != 'SYSTEM';


set heading off
select '24、查询使用rollback segment时等待比率' from dual;
set heading on
SELECT ROUND(SUM(waits / gets) * 100, 2) || '%' "Contention"
  FROM v$rollstat;


set heading off
select '25、查询使用rollback segment时等待比率及其平局活动事务数' from dual;
set heading on
COL contention FORMAT 9999999990;
SELECT AVG(xacts) "Trans per RBS",
       ROUND(SUM(waits / gets) * 100, 2) || '%' "Contention"
  FROM v$rollstat;




set heading off
select '五、检查Oracle数据库性能' from dual;


set heading off
select '1、检查数据库的等待事件' from dual;
set heading on
set pages 80
set lines 120
col event for a40
select sid,event,p1,p2,p3,WAIT_TIME,SECONDS_IN_WAIT from v$session_wait where event not like 'SQL%' and event not like 'rdbms%';


set heading off
select '2、查看与redo相关等待事件' from dual;
set heading on
col event format a40
select event,total_waits,total_timeouts,average_wait from v$system_event where upper(event) like'%REDO%';

set heading off
select '3、查看session redo event' from dual;
set heading on
select event,total_waits,total_timeouts,average_wait from v$session_event where upper(event) like'%REDO%';

set heading off
select '4、Disk Read最高的SQL语句的获取' from dual;
set heading on
SELECT SQL_TEXT FROM (SELECT * FROM V$SQLAREA ORDER BY DISK_READS) WHERE ROWNUM<=5  order  by SQL_TEXT desc;


set heading off
select '5、查找前十条性能差的sql' from dual;
set heading on
SELECT *
  FROM (SELECT PARSING_USER_ID EXECUTIONS,
               SORTS,
               COMMAND_TYPE,
               DISK_READS,
               SQL_TEXT
          FROM V$SQLAREA
         ORDER BY DISK_READS DESC)
 WHERE ROWNUM < 10;


set heading off
select '6、等待时间最多的5个系统等待事件的获取' from dual;
set heading on
SELECT * FROM (SELECT * FROM V$SYSTEM_EVENT WHERE EVENT NOT LIKE 'SQL%' ORDER BY TOTAL_WAITS DESC) WHERE ROWNUM<=5;


set heading off
select '7、检查运行很久的SQL' from dual;
set heading on
COLUMN USERNAME FORMAT A12 
COLUMN OPNAME FORMAT A16 
COLUMN PROGRESS FORMAT A8 
SELECT USERNAME,
       SID,
       OPNAME,
       ROUND(SOFAR * 100 / TOTALWORK, 0) || '%' AS PROGRESS,
       TIME_REMAINING,
       SQL_TEXT
  FROM V$SESSION_LONGOPS, V$SQL
 WHERE TIME_REMAINING <> 0
   AND SQL_ADDRESS = ADDRESS
   AND SQL_HASH_VALUE = HASH_VALUE;


set heading off
select '9、检查碎片程度高的表' from dual;
set heading on
SELECT segment_name table_name,COUNT(*) extents FROM dba_segments WHERE owner NOT IN 
('SYS', 'SYSTEM') GROUP BY segment_name HAVING COUNT(*)=(SELECT MAX(COUNT(*)) 
FROM dba_segments GROUP BY segment_name);


set heading off
select '10、检查死锁及处理' from dual;
set heading on

col sid for 999999
col username for a10
col schemaname for a10
col osuser for a16
col machine for a16
col terminal for a20
col owner for a10
col object_name for a30
col object_type for a10
select sid,
       serial#,
       username,
       SCHEMANAME,
       osuser,
       MACHINE,
       terminal,
       PROGRAM,
       owner,
       object_name,
       object_type,
       o.object_id
  from dba_objects o, v$locked_object l, v$session s
 where o.object_id = l.object_id
   and s.sid = l.session_id;



set heading off
select '11、查看数据库中行chain' from dual;
set heading on
SELECT 'Chained Rows ' "Ratio" 
       , ROUND(
         (SELECT SUM(value) FROM V$SYSSTAT WHERE name = 'table fetch continued row') / (SELECT SUM(value) FROM V$SYSSTAT WHERE name IN ('table scan rows gotten', 'table fetch by rowid'))
         * 100, 3)||'%' "Percentage"
FROM DUAL;



set heading off
select '12、查询解析比率' from dual;
set heading on

SELECT 'Soft Parses ' "Ratio",
       ROUND(((SELECT SUM(value)
                 FROM V$SYSSTAT
                WHERE name = 'parse count (total)') -
             (SELECT SUM(value)
                 FROM V$SYSSTAT
                WHERE name = 'parse count (hard)')) /
             (SELECT SUM(value) FROM V$SYSSTAT WHERE name = 'execute count') * 100,
             2) || '%' "Percentage"
  FROM DUAL
UNION
SELECT 'Hard Parses ' "Ratio",
       ROUND((SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name = 'parse count (hard)') /
             (SELECT SUM(value) FROM V$SYSSTAT WHERE name = 'execute count') * 100,
             2) || '%' "Percentage"
  FROM DUAL
UNION
SELECT 'Parse Failures ' "Ratio",
       ROUND((SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name = 'parse count (failures)') /
             (SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name = 'parse count (total)') * 100,
             5) || '%' "Percentage"
  FROM DUAL;


set heading off
select '13、查看与latch有关的event信息' from dual;
set heading on
COL event FORMAT a20;
COL waits FORMAT 9999990;
COL timeouts FORMAT 99999990;
COL average FORMAT 99999990;
SELECT event          "Event",
       time_waited    "Total Time",
       total_waits    "Waits",
       average_wait   "Average",
       total_timeouts "Timeouts"
  FROM V$SYSTEM_EVENT
 WHERE event = 'latch free'
 ORDER BY EVENT;




set heading off
select '14、查看大表小表扫描对应的值' from dual;
set heading on

SELECT value, name
  FROM V$SYSSTAT
 WHERE name IN ('table fetch by rowid',
                'table scans (short tables)',
                'table scans (long tables)');

SELECT 'Short to Long Full Table Scans' "Ratio",
       ROUND((SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name = 'table scans (short tables)') /
             (SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name IN ('table scans (short tables)',
                              'table scans (long tables)')) * 100,
             2) || '%' "Percentage"
  FROM DUAL
UNION
SELECT 'Short Table Scans ' "Ratio",
       ROUND((SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name = 'table scans (short tables)') /
             (SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name IN ('table scans (short tables)',
                              'table scans (long tables)',
                              'table fetch by rowid')) * 100,
             2) || '%' "Percentage"
  FROM DUAL
UNION
SELECT 'Long Table Scans ' "Ratio",
       ROUND((SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name = 'table scans (long tables)') /
             (SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name IN ('table scans (short tables)',
                              'table scans (long tables)',
                              'table fetch by rowid')) * 100,
             2) || '%' "Percentage"
  FROM DUAL
UNION
SELECT 'Table by Index ' "Ratio",
       ROUND((SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name = 'table fetch by rowid') /
             (SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name IN ('table scans (short tables)',
                              'table scans (long tables)',
                              'table fetch by rowid')) * 100,
             2) || '%' "Percentage"
  FROM DUAL
UNION
SELECT 'Efficient Table Access ' "Ratio",
       ROUND((SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name IN
                     ('table scans (short tables)', 'table fetch by rowid')) /
             (SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name IN ('table scans (short tables)',
                              'table scans (long tables)',
                              'table fetch by rowid')) * 100,
             2) || '%' "Percentage"
  FROM DUAL;





set heading off
select '15、index使用比率' from dual;
set heading on

col name for a30
SELECT to_char(value, '999999999999999999999'), name
  FROM V$SYSSTAT
 WHERE name IN ('table fetch by rowid',
                'table scans (short tables)',
                'table scans (long tables)')
    OR name LIKE 'index fast full%'
    OR name = 'index fetch by key';
       
SELECT 'Index to Table Ratio ' "Ratio",
       ROUND((SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name LIKE 'index fast full%'
                  OR name = 'index fetch by key'
                  OR name = 'table fetch by rowid') /
             (SELECT SUM(value)
                FROM V$SYSSTAT
               WHERE name IN ('table scans (short tables)',
                              'table scans (long tables)')),
             0) || ':1' "Result"
  FROM DUAL;



set heading off
select '16、等待class' from dual;
set heading on
col wait_class for a30                                  
SELECT wait_class, COUNT(wait_class) FROM v$system_event
GROUP BY wait_class ORDER BY 1; 
