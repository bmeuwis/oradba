#!/bin/ksh
#set -x
#
# Version 1.4
# -----------
#
# Update by Jan David 2011/10/14 (version 1.4)
#       Added support for Linux and HP-UX.
#
# Update by Bart Meuwis 2006/08/17 (version 1.3)
#       Added use of fuser to determine file in use.
#       Got rid of max_logs, unneeded if fuser is used.
#       Added use of pipe to compress directly to other side.
#
# Update by Alain Servais 2005/08/02 (version 1.2)
#       Extra parameter max_logs added.
#
# Update by Jan David 2005/01/19 (version 1.1)
#       Oracle version test did not work properly - fixed.
#
# Created by Alain Servais 2004/12/01 (version 1.0)
#
# This archiver_disk script stages all Oracle archives
# off to a NFS repository when they are found in the current
# archive-dir and not in use.
#
#set -x

# -----------------------------------------------------------------
log_it () {
# -----------------------------------------------------------------
  print "`date` ($$) ${@}" >> ${LOGFILE}
# Uncomment next line for realtime logging on screen
print "`date` ($$) ${@}"
}

# -----------------------------------------------------------------
check_lockfile () {
# -----------------------------------------------------------------
log_it "Checking for lockfile ..."
if [ -r ${LOCKFILE} ]
then
         while [ -r ${LOCKFILE} ]
         do      # Lockfile exists, examining whether process still running ...
                 log_it "Lockfile exists with pid `cat ${LOCKFILE}`"
                 LOCK_PID="X`cat ${LOCKFILE}`X"
                 STILL_RUNNING=`ps -ef | awk '{ print "X"$2"X" }' | grep ${LOCK_PID} | wc -l`
                 if [ ${STILL_RUNNING} -eq 0 ]
                 then            # Process not running anymore, removing this lockfile ...
                                 log_it "Process not running anymore, removing this lockfile ..."
                                 rm -f ${LOCKFILE}
                 else            # Process is still running, exiting ...
                                 log_it "Process `cat ${LOCKFILE}` still running - exiting ..."
                        exit 0;
                 fi
         done
# Lockfile does not exist (anymore) - continuing running this script !
fi
}

# -----------------------------------------------------------------
run_debug () {
# -----------------------------------------------------------------
log_it "--> Variables used :"
log_it "...... RESULT      = " $result
log_it "...... ARCHDIR     = " $ARCHDIR
log_it "...... LOGFILE     = " $LOGFILE
log_it "...... STAGEDIR    = " $STAGEDIR
log_it "...... ORACLE_HOME = " $ORACLE_HOME
log_it "...... CNT         = " $CNT
log_it "...... CNTNEW      = " $CNTNEW
}

# START OF MAIN PROGRAM #
#########################

#
# Set OS specific customizations
#
OSVERSION="`uname -s`"
if [[ $OSVERSION = "SunOS" || $OSVERSION = "HP-UX" ]]; then
        export FUSER=/usr/sbin/fuser
else
        export FUSER=/sbin/fuser
fi

#
# Check if the user has supplied the correct number of arguments
#
if [ $# = 0 ]; then
   print "\nUsage: $(basename $0) ORACLE_SID [number of files to keep] [debug <Y/N>] \n"
   exit 0
fi

#
# Set the generic parameters
#
export ORACLE_SID=$(print $1|tr '[a-z]' '[A-Z]')
export ORACLE_HOME=$(grep -v "^#" /var/opt/oracle/oratab | grep ${ORACLE_SID} | cut -f2 -d:)
export LOCKFILE=/var/tmp/archiver_disk_${ORACLE_SID}.lck
export LOGFILE=/oracle/${ORACLE_SID}/logs/archiver.log
export STAGEDIR=/oracle/hsmstage/${ORACLE_SID}/oraarch
export STAGEDIR2=/oracle/hsmstage/${ORACLE_SID}.`hostname`/oraarch
export LOCATION_FILE=/var/tmp/.archlocation_$ORACLE_SID
export SQLPLUS="$ORACLE_HOME/bin/sqlplus"
PAR2=$3

check_lockfile
print $$ > ${LOCKFILE}

# Set the correct STAGEDIR

if [ -d $STAGEDIR2 ]; then
   export STAGEDIR=$STAGEDIR2
fi

log_it Using stagedir $STAGEDIR

#
# Pick the correct directory from the database

result=`echo "archive log list" | $SQLPLUS -s "/ as sysdba" | grep -i "archive destination" | awk '{ print $3 }'`
subresult=`print $result | cut -b 1`

if [ "${subresult}" != "/" ]; then
   result=`cat $LOCATION_FILE`
   log_it "ERROR: Problem with Oracle connect - pls. verify."
   log_it "Will continue with data from previous sessions, ie."
   log_it "    using $result for archiving directory."
fi

if [ -d ${result} ]; then
   ARCHDIR=${result}
   print $ARCHDIR > $LOCATION_FILE
elif [ -d `dirname ${result}` ]; then
   ARCHDIR=`dirname ${result}`
   print $ARCHDIR > $LOCATION_FILE
else
   log_it "ERROR: No correct archive dir found - pls. verify."
   rm -f ${LOCKFILE}
   exit 1;
fi

# Setting the number of files to be archived.
# If no parameter is given to this script, the number will be the total files found minus 10.
# This is necessary for the Data Guard installs.
# If a numerical parameter is passed, then that number of files will remain and that can be 0.

# TODO : add check for number !

PAR1=$2
KEEP=${PAR1:=10}
CNT=`ls -1tr $ARCHDIR/*.dbf | wc -l`
CNTNEW=`echo $CNT-$KEEP | bc`

[[ "$PAR2" -eq "Y" ]] && run_debug

if [ $CNTNEW -lt 0 ];then
   log_it Not enough files to process if keeping $KEEP, stopping the script.
   exit 0
fi

#
# Archive the Oracle logs
#

log_it "Archiving started for ${ORACLE_SID}, $CNTNEW file(s) to process, keeping $KEEP ..."


ls -1 ${ARCHDIR}/*.dbf > /dev/null 2>&1
if [ "$?" -eq "2" ]; then
   log_it "No files found to archive !\n"
   rm ${LOCKFILE}
   exit 0;
fi

NEWCNT=1

for x in `ls -1tr ${ARCHDIR}/*.dbf | head -$CNTNEW`
do
STAGEFILE=${STAGEDIR}/`basename ${x}`.gz
log_it "--> Processing ${x} ($NEWCNT of $CNTNEW)"
fresult=`${FUSER} -u ${x} 2>&1 | awk '{ print $2 }'`
    if [ "${fresult}" != "" ]; then
                log_it "...... File is in use - skipping ... "
        elif [ "${fresult}" = "" ]; then
                log_it "...... File is not in use - continuing ... "
                cat ${x} |gzip -1 > ${STAGEFILE}
                        ORIGSIZE=`ls -l ${x} | awk '{ print $5 }'`
                        GZIPSIZE=`gunzip -l ${STAGEFILE} | tail -1 | awk '{ print $2 }'`
                        gunzip -t ${STAGEFILE}
                        GZIPTEST=$?
                        if [ ${ORIGSIZE} -eq ${GZIPSIZE} -a ${GZIPTEST} -eq 0 ]; then
                                rm  ${x}
                                DF=`df -h /oracle/${ORACLE_SID}/oraarch|tail -1|awk '{ print $4 }'`
                                log_it "...... File gzipped and transferred to ${STAGEDIR} "
                                log_it "...... /oracle/${ORACLE_SID}/oraarch currently at ${DF} "
                        else
                                log_it "...... ARCHIVER ERROR: filesizes do not match or test = ${GZIPTEST} !"
                        fi
        fi
NEWCNT=`echo $NEWCNT+1 | bc`
done

log_it "Archiving stopped for ${ORACLE_SID}.\n"

#
# Rotate logfile if it's to big
# and cleanup lockfile
#

if [ `wc -l ${LOGFILE} | awk '{ print $1 }'` -gt 10000 ]; then
  log_it "...... Logfile oversized - archiving to ${LOGFILE}.old"
  mv ${LOGFILE} ${LOGFILE}.old
  log_it "NEW LOGFILE STARTED - OLD ONE is ${LOGFILE}.old"
fi

rm ${LOCKFILE}

exit 0
