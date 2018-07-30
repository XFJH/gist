# track_table_alter 
# 跟踪模型变更记录

通过保存模型基本信息（字段备注，字段名，数据类型，是否非空，是否主键，字段顺序），来跟踪模型的变化记录。

t_track_table  // 跟踪表
tmp_track_table  // 临时表（保存最新记录的数据，每次比较晚就会被删除）

compare_engine.sql
    * 比较引擎，这个文件实现了比较的核心逻辑

create_pre_table.sql
    * 创建用于存储数据的表。T_TRACK_TABLE, TMP_TRACK_TABLE

find_current_table_differences_to_history_table.sql
    * 查询当前模型跟跟踪表之间字段数目相异表


 