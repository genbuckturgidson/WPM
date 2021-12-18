#####################
# THE COPY FUNCTION #
#####################

function copy() {

  POSIT=()
  while [[ $# -gt 0 ]]; do
    KEY="$1"
	case $KEY in
      -o|--oldname) OLDNAME=$2; shift;;
      -n|--newname) NEWNAME=$2; shift;;
      -s|--source) SOURCE=$2; shift;;
      -d|--destination) DESTDIR=$2; shift ;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"

  [ -d $SOURCE ] || echo "source directory does not exist"
  [ -d $SOURCE ] || exit 1

  [ -f $SOURCE/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $SOURCE/wp-config.php ] || exit 1

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM COPY CALLED ON $DATETIME WITH VERSION $WPVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing copy from $SOURCE to $DESTDIR" | tee -a $LOGFILE

  [ -d $DESTDIR ] || try mkdir -p $DESTDIR
  try rsync -aq $SOURCE/* $DESTDIR
  echo "==$INSTANCEID==File copy complete." | tee -a $LOGFILE

  cd $DESTDIR

  local DBNAME=`grep DB_NAME wp-config.php | awk -F "'" '{print $4}'`
  local DBUSER=`grep DB_USER wp-config.php | awk -F "'" '{print $4}'`

  echo "==$INSTANCEID==Database $DBNAME with user $DBUSER." | tee -a $LOGFILE
  if mysql "${DBNAME}" >/dev/null 2>&1 </dev/null; then
    echo "==$INSTANCEID==DB ${DBNAME} exists and I have access to it" | tee -a $LOGFILE
  else
    echo "==$INSTANCEID==${DBNAME} doesn't exist, or I can't access it. Terminating." | tee -a $LOGFILE
    exit 1
  fi

  try mysqldump $DBNAME --single-transaction > $TEMPDIR/$DBNAME.sql
  echo "==$INSTANCEID==DB dump to SQL file is complete." | tee -a $LOGFILE

  echo "==$INSTANCEID==Changing $SOURCE to $DESTDIR with sed" | tee -a $LOGFILE
  try find `pwd` -type f -exec sed -i "s/$SOURCE/$DESTDIR/g" '{}' \;
  try sed -i "s|$SOURCE|$DESTDIR|g" $TEMPDIR/$DBNAME.sql
  echo "==$INSTANCEID==Sed complete." | tee -a $LOGFILE
  
  echo "==$INSTANCEID==Running fixserial on $TEMPDIR/$DBNAME.sql" | tee -a $LOGFILE
  try 6b4178521b3f/lib/fixserial.sh -o $OLDNAME -n $NEWNAME -f $TEMPDIR/$DBNAME.sql
  echo "==$INSTANCEID==Fixserial has been run." | tee -a $LOGFILE

  [ -e "$SOURCE/.htaccess" ] && cp -v $SOURCE/.htaccess $DESTDIR/.htaccess
  [ -d "$SOURCE/.ssh" ] && cp -vR $SOURCE/.ssh $DESTDIR/
  [ -e "$SOURCE/wp-content/uploads/.htaccess" ] && cp -v $SOURCE/wp-content/uploads/.htaccess $DESTDIR/wp-content/uploads/.htaccess
  echo "==$INSTANCEID==Dot files copied (if they existed)." | tee -a $LOGFILE
  
  local NEWDB=${DBNAME}
  NEWDB+=`openssl rand -hex 2`
  echo "==$INSTANCEID==New database name is ${NEWDB}" | tee -a $LOGFILE

  if mysql "${NEWDB}" >/dev/null 2>&1 </dev/null;then
    echo "==$INSTANCEID==${NEWDB} somehow already exists. Terminating." | tee -a $LOGFILE
    exit 1
  fi

  echo "==$INSTANCEID==Running DB import to ${NEWDB}" | tee -a $LOGFILE
  try mysql -e "create database ${NEWDB}"
  try mysql -e "grant all on ${NEWDB}.* to ${DBUSER}"
  try mysql -e "flush privileges"
  try mysql "${NEWDB}" < $TEMPDIR/${DBNAME}.sql
  echo "==$INSTANCEID==DB import to ${NEWDB} is complete." | tee -a $LOGFILE
  
  rm -f $TEMPDIR/${DBNAME}.sql
  echo "==$INSTANCEID==SQL file has been removed." | tee -a $LOGFILE

  try sed -i "s/DB_NAME', '${DBNAME}/DB_NAME', '${NEWDB}/" $DESTDIR/wp-config.php
  echo "==$INSTANCEID==Config file updated with new database." | tee -a $LOGFILE

  echo "==$INSTANCEID==Running permissions" | tee -a $LOGFILE
  try chown --reference=$SOURCE $DESTDIR
  permissions $DESTDIR
  echo "==$INSTANCEID==Permissions complete." | tee -a $LOGFILE

  echo "==$INSTANCEID==Copy of $OLDNAME to $NEWNAME completed." | tee -a $LOGFILE

} # END COPY
