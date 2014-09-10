column  TYPE format a30
column SCHEMANAME format a10
column EVENT format a30
column WAIT_CLASS format a30

select  type,schemaname, module, BLOCKING_SESSION_STATUS,event, WAIT_CLASS 
from v$session where sid in ('519','520');





