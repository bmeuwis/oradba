set pagesize 1000
set linesize 100

break on owner skip 1 on segment_type

column owner format a15
column segment_type format a15
column segment_name format a45
column Mb format 9999999

select * from 
(select owner, segment_type, segment_name, round(bytes/1024/1024) Mb
from dba_segments
where bytes/1024/1024 > 1250
and segment_type like 'TABLE%'
order by 1 asc,2 asc,4 desc)
where rownum < 11
/

select * from 
(select owner, segment_type, segment_name, round(bytes/1024/1024) Mb
from dba_segments
where bytes/1024/1024 > 1250
and segment_type like 'INDEX%'
order by 1 asc,2 asc,4 desc)
where rownum < 11
/
