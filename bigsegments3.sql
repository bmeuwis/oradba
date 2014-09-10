select owner || '.' || segment_name, round(bytes/1024/1024) Mb from dba_segments
order by bytes asc
/
