-- Using sys_dba_segs in stead of dba_segemnts because of bug in bytes-column
-- giving negative number iso correct value

set heading on

compute SUM of delta_mb on ttable


column ttable format a38
column lraw format 9999
column blob format 9999
set pagesize 1000
set linesize 132

select * from
(select 
--t.tablespace_name, 
t.owner || '.' || t.table_name ttable, t.num_rows, t.avg_row_len,
round(t.num_rows*t.avg_row_len/1024/1024) table_mb, round(s.bytes/1024/1024) segment_mb,
round(s.bytes/1024/1024) - round(t.num_rows*t.avg_row_len/1024/1024) delta_mb,
t.last_analyzed, sq.lraw, sq2.blob
from dba_tables t, sys_dba_segs s, 
   (select table_name, count(*) lraw from dba_tab_columns where data_type = 'LONG RAW' group by table_name) sq,
   (select table_name, count(*) blob from dba_tab_columns where data_type = 'BLOB' group by table_name) sq2
where t.table_name = s.segment_name
and t.table_name = sq.table_name (+)
and t.table_name = sq2.table_name (+)
and t.tablespace_name like upper('%&Tablespace_name%')
and s.segment_type = 'TABLE'
and t.last_analyzed is not null
and s.bytes > 500000000
and round(s.bytes/1024/1024) > round(t.num_rows*t.avg_row_len/1024/1024)*1.5
and t.owner not in ('SYS','SYSTEM','PERFSTAT')
and t.table_name not in ('ARFCSSTATE','ARFCSDATA')
order by round(s.bytes/1024/1024) - round(t.num_rows*t.avg_row_len/1024/1024) desc)
where rownum < 61
order by lraw, delta_mb  desc
/
set heading off
select 'Database ==> ' || name from v$database;
set heading on


