-- Using sys_dba_segs in stead of dba_segemnts because of bug in bytes-column
-- giving negative number iso correct value

set heading on

compute SUM of delta_mb on ttable


column ttable format a38
set pagesize 1000
set linesize 132
select * from
(select 
t.tablespace_name, 
t.owner || '.' || t.table_name ttable, t.num_rows, t.avg_row_len,
round(t.num_rows*t.avg_row_len/1024/1024) table_mb, round(s.bytes/1024/1024) segment_mb,
round(s.bytes/1024/1024) - round(t.num_rows*t.avg_row_len/1024/1024) delta_mb,
t.last_analyzed, sq.longraw
from dba_tables t, sys_dba_segs s, (select table_name, count(*) longraw from dba_tab_columns
   where data_type = 'LONG RAW' group by table_name) sq
where t.table_name = s.segment_name
and t.table_name = sq.table_name (+)
and s.segment_type = 'TABLE'
and t.last_analyzed is not null
--and s.segment_name in ('TST03','APQD','SRRELROLES','IDOCREL')
and s.bytes > 500000000
and round(s.bytes/1024/1024) > round(t.num_rows*t.avg_row_len/1024/1024)*1.5
and t.owner not in ('SYS','SYSTEM','PERFSTAT')
order by t.tablespace_name, round(s.bytes/1024/1024) - round(t.num_rows*t.avg_row_len/1024/1024) desc)
where rownum < 31
/
set heading off
select 'Database ==> ' || name from v$database;
set heading on


