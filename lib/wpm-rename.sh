#######################
# THE RENAME FUNCTION #
#######################

function rename() {	
  POSIT=();
  while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
      -o|--oldname) OLDNAME=$2; shift;;
      -n|--newname) NEWNAME=$2; shift;;
      -p|--path) DESTDIR=$2; shift;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"
  
  DESTDIR=${DESTDIR:-`pwd`}
  if [ ! -d $DESTDIR ]; then
    echo "$DESTDIR doesn't exist"
    exit 1
  fi

  [ -f wp-config.php ] || echo "This isn't a wordpress installation."
  [ -f wp-config.php ] || exit 1

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM RENAME CALLED ON $DATETIME WITH VERSION $WPVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing rename from $OLDNAME to $NEWNAME" | tee -a $LOGFILE

  local DBNAME=`grep DB_NAME wp-config.php | awk -F "'" '{print $4}'`

  echo "==$INSTANCEID==Database is $DBNAME" | tee -a $LOGFILE

  if mysql "${DBNAME}" >/dev/null 2>&1 </dev/null; then
    echo "==$INSTANCEID==${DBNAME} exists and I have access to it" | tee -a $LOGFILE
  else
    echo "==$INSTANCEID==$DBNAME doesn't exist, or I can't access it. Terminating." | tee -a $LOGFILE
    exit 1
  fi

  echo "==$INSTANCEID==Doing DB transform" | tee -a $LOGFILE
  try mysqldump $DBNAME --single-transaction > ${TEMPDIR}/${DBNAME}.${DATETIME}.sql
  sed -i "s/${OLDNAME}/${NEWNAME}/g" ${TEMPDIR}/${DBNAME}.${DATETIME}.sql
  try 6b4178521b3f/lib/fixserial.sh -o $OLDNAME -n $NEWNAME -f ${TEMPDIR}/${DBNAME}.${DATETIME}.sql
  try mysql "$DBNAME" < $TEMPDIR/${DBNAME}.${DATETIME}.sql
  echo "==$INSTANCEID==DB transform complete" | tee -a $LOGFILE

  echo "==$INSTANCEID==Changing $OLDNAME to $NEWNAME" | tee -a $LOGFILE
  try find . -type f -exec sed -i "s/$OLDNAME/$NEWNAME/g" {} +

  try rm -fv ${TEMPDIR}/${DBNAME}.${DATETIME}.sql

  echo "==$INSTANCEID==Rename of $OLDNAME to $NEWNAME complete" | tee -a $LOGFILE

} # END RENAME
