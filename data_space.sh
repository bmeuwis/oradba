if [ "`uname -s`" = "SunOS" ]; then
        echo "Filesystem            kbytes    used   avail capacity  Mounted on"
        df -h | egrep -e 'sapdata|oradata'  | grep $ORACLE_SID | sort -n -k 5;
elif [ "`uname -s`" = "Linux" ]; then
        echo "Volume                    Space Available (GB)"
        (for DIR in /oracle/$ORACLE_SID/*data*; do
        if [ -d $DIR ]; then
                GB_FREE=`df -h $DIR | tail -1 |  awk '{print $4}'`
                echo "$DIR              $GB_FREE"
        fi
        done) | sort
else
        echo "Volume                    Space Available (MB)"
        (for DIR in /oracle/$ORACLE_SID/*data*; do
        if [ -d $DIR ]; then
                KB_FREE=`df -k $DIR | grep free | awk '{print $1}'`
                let MB_FREE=KB_FREE/1024
                echo "$DIR              $MB_FREE"
        fi
        done) | sort
fi 
