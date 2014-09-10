set echo off verify off pause off linesize 120 pagesize 1000

column name format a5
column file_name format a54
column tablespace_name format a15

break on name on tablespace_name skip 1

compute SUM of btot on tablespace_name
compute SUM of bfree on tablespace_name
compute SUM of autoext on tablespace_name

SELECT d.name, ddf.tablespace_name, ddf.file_name,
ddf.bytes/1024/1024 btot,
round(sum(dfs.bytes)/1024/1024) bfree,
--round((sum(dfs.bytes)/ddf.bytes)*100) perc,
--decode(ddf.autoextensible,'YES',' YES','') "AUTO ?"
to_number(decode(ddf.maxbytes,0,'',round((maxbytes-ddf.bytes)/1024/1024))) autoext
FROM dba_data_files ddf, dba_free_space dfs, v$database d
WHERE upper(ddf.tablespace_name) like '%' || upper('&&tablespace_name')
and ddf.file_id = dfs.file_id (+)
group by d.name, ddf.tablespace_name, ddf.file_name, ddf.bytes/1024/1024 ,
ddf.bytes,
decode(ddf.maxbytes,0,'',round((maxbytes-ddf.bytes)/1024/1024))
--decode(ddf.autoextensible,'YES',' YES','')
order by 1,2,4 desc;

host sh /home/awnqg/backup/data_space.sh

undef tablespace_name
