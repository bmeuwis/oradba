-- Create a directory called mydump if it does not exist yet :
drop directory mydump;
create directory mydump as '/oracle/exports/&SID';
grant read, write on directory mydump to system;
grant read, write on directory mydump to exp_full_database;
grant read, write on directory mydump to imp_full_database;

prompt Run as root :
prompt mkdir -p /oracle/exports
prompt chown oracle:dba /oracle/exports
prompt mount -F nfs nfsgm:/gm/exports /oracle/exports

