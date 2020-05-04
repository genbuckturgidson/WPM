#######################
# THE BACKUP FUNCTION #
#######################

function backup() {

  POSIT=()
  while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
      -n|--no-compress) NOCOMPRESS="yes" ;;
      -d|--delete-old) DELETEOLD="yes" ;;
      -s|--skip-uploads) SKIPUPLOADS="yes" ;;
      -p|--path) DESTDIR="$2" ; shift ;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
	shift
  done
  set -- "${POSIT[@]}"

  DELETEOLD="${DELETEOLD:-no}"
  SKIPUPLOADS="${SKIPUPLOADS:-no}"
  DESTDIR="${DESTDIR:-`pwd`}"

  MEMORY=$( echo $((`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`/1024)) )
  if [[ $MEMORY -lt 675 ]]; then
    NOCOMPRESS="yes"
  else
    NOCOMPRESS="${NOCOMPRESS:-no}"
  fi

  [ -f ${DESTDIR}/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f ${DESTDIR}/wp-config.php ] || exit 1

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM BACKUP CALLED ON $DATETIME WITH VERSION $WPMVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing backup on $DESTDIR" >> $LOGFILE

  cd $DESTDIR

  local NAME=`echo $DESTDIR | rev | cut -d '/' -f 1 | rev`

  if [ "$NAME" == "" ] || [ ${#NAME} -lt 3 ] || [ "$NAME" == "html" ]; then
    NAME=`hostname -f`
  fi

  echo "==$INSTANCEID==The name is ${NAME}" | tee -a $LOGFILE

  local DBNAME=`grep DB_NAME wp-config.php | awk -F "'" '{print $4}'`
  echo "==$INSTANCEID==The DB name is ${DBNAME}" | tee -a $LOGFILE

  if mysql "${DBNAME}" >/dev/null 2>&1 </dev/null; then
    echo "==$INSTANCEID==${DBNAME} exists (and I have permission to access it)" | tee -a $LOGFILE
  else
    echo "==$INSTANCEID==${DBNAME} doesn't exist or I lack access, terminating" | tee -a $LOGFILE
    exit 1
  fi

  echo "==$INSTANCEID==Starting the DB dump" | tee -a $LOGFILE
  try mysqldump $DBNAME --single-transaction > $TEMPDIR/${DBNAME}.${DATETIME}.sql
  echo "==$INSTANCEID==The database dump is complete." | tee -a $LOGFILE

  if [ "$BACKUPPATH" == "PARENTOFGIVEN" ]; then
    BACKUPPATH=`dirname $DESTDIR`
    DELETEOLD="no"
  fi

  if [ "$DELETEOLD" == "yes" ]; then
    try find $BACKUPPATH -mtime +1 -type f -exec rm -fv '{}' \;;
    echo "==$INSTANCEID==removed old backups" | tee -a $LOGFILE;
  fi

  if [[ "${SKIPUPLOADS}" == "no" ]]; then
    local SF=`echo $(($(stat -f --format="%a*%S" .)))`;
    local SN=`du -sb .|awk '{print $1}'`;
    local SB=${SN}
    local SN=`echo $(($SN + $SN))`;
    if [ $SF -gt $SN ]; then
      echo "==$INSTANCEID==Adequate free space detected" | tee -a $LOGFILE
    else
      echo "==$INSTANCEID==Insufficient space available. Terminating" | tee -a $LOGFILE
      exit 1
    fi
  fi

  echo "==$INSTANCEID==Starting archive creation" | tee -a $LOGFILE

  [ `which xz` ] && COMPRESSOR="xz"
  [ `which pv` ] && PROGRESS="pv"
  
  if [ "$PROGRESS" == "pv" ]; then
  	TAROPTIONS="cf"
  	INTERPRED="pv -per -s${SB} |"
  else
  	TAROPTIONS="cfv"
  	INTERPRED=""
  fi
  
  if [ "$SKIPUPLOADS" == "yes" ]; then
  	EXCLUDES="--exclude=\"${DESTDIR}/wp-content/uploads\""
  else
  	EXCLUDES=""
  fi
  
  if [ "$NOCOMPRESS" == "yes" ]; then
  	if [ "$COMPRESSOR" == "xz" ]; then
  		PRED="xz -0 > $BACKUPPATH/$NAME.$DATETIME.tar.xz"
  	else
  		PRED="gzip -1 > $BACKUPPATH/$NAME.$DATETIME.tar.gz"
  	fi
  else
  	if [ "$COMPRESSOR" == "xz" ]; then
  		PRED="xz -9 > $BACKUPPATH/$NAME.$DATETIME.tar.xz"
  	else
  		PRED="gzip -9 > $BACKUPPATH/$NAME.$DATETIME.tar.gz"
  	fi
  fi
  
  [ `which getfacl` ] && getfacl -R `pwd` > .permissions_backup.${DATETIME}
  [ `which getfacl` ] && echo "==$INSTANCEID==Permissions backup completed." | tee -a $LOGFILE
  [ `which getfacl` ] && echo "==$INSTANCEID==Restore with setfacl --restore=${$DESTDIR}/.permissions_backup.${DATETIME}" | tee -a $LOGFILE
  
  CMD="try tar $TAROPTIONS - --transform=\"flags=r;s|^|$DATETIME/|\" --show-transformed * $TEMPDIR/$DBNAME.$DATETIME.sql $EXCLUDES | $INTERPRED $PRED"
  
  eval $CMD

  rm -f $TEMPDIR/$DBNAME.$DATETIME.sql

  echo "==$INSTANCEID==The archive is available at $BACKUPPATH/$NAME.$DATETIME.tar.xz"

} # END BACKUP
