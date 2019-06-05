#####################
# THE COPY FUNCTION #
#####################

function copy() {

	POSIT=()
	while [[ $# -gt 0 ]]
	do
		key="$1"
		case $key in
    	-o|--oldname) OLDN=$2; shift;;
    	-n|--newname) NEWN=$2; shift;;
    	-s|--source) OLDP=$2; shift;;
    	-d|--destination) NEWP=$2; shift ;;
    	*) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"

  [ -d $OLDP ] || echo "old directory does not exist"
  [ -d $OLDP ] || exit 1

  [ -f $OLDP/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $OLDP/wp-config.php ] || exit 1

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM COPY CALLED ON $dt WITH VERSION $WPVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing copy from $OLD to $NEWP" >> $LOGFILE

  [ -d $NEWP ] || try mkdir -p $NEWP

  echo "copying site from $OLDP to $NEWP"
  try rsync -aq $OLDP/* $NEWP

  cd $NEWP
  echo "file copy complete"
  echo "doing DB dump"

  local dbname=`grep DB_NAME wp-config.php | awk -F "'" '{print $4}'`
  local dbuser=`grep DB_USER wp-config.php | awk -F "'" '{print $4}'`

  echo "=$r=Database $dbname with $dbuser being dumped" >> $LOGFILE
  if mysql "${dbname}" >/dev/null 2>&1 </dev/null; then
    echo "${dbname} exists (and I have permission to access it)"
    echo "=$r=DB exists and I have access to it" >> $LOGFILE
  else
    echo "${dbname} does not exist (or I do not have permission to access it)"
    echo "refusing to continue"
    echo "=$r=DB doesn't exist, or I can't access it. Terminating." >> $LOGFILE
    exit 1
  fi

  try mysqldump $dbname --single-transaction > $TEMPDIR/$dbname.sql

  echo "doing find/replace"
  echo "=$r=changing $OLDP to $NEWP" >> $LOGFILE

  try find . -type f -exec sed -i "s/$OLDP/$NEWP/g" {} +
  try sed -i "s|$OLDP|$NEWP|g" $TEMPDIR/$dbname.sql

  echo "fixing serialized php array values"
  echo "=$r=Running fixserial on $TEMPDIR/$dbname.sql" >> $LOGFILE
  try 6b4178521b3f/lib/fixserial.sh -o $OLDN -n $NEWN -f $TEMPDIR/$dbname.sql

  [ -e "$OLDP/.htaccess" ] && cp -v $OLDP/.htaccess $NEWP/.htaccess || echo "no htaccess file in old docroot"
  [ -d "$OLDP/.ssh" ] && cp -vR $OLDP/.ssh $NEWP/ || echo "no ssh directory in old docroot"
  [ -e "$OLDP/wp-content/uploads/.htaccess" ] && cp -v $OLDP/wp-content/uploads/.htaccess $NEWP/wp-content/uploads/.htaccess || echo "no htaccess in old uploads directory"

  echo "doing DB import"
  local newdb=${dbname}
  newdb+=`openssl rand -hex 2`

  if mysql "${newdb}" >/dev/null 2>&1 </dev/null;then
    echo "$newdb already exists, refusing to continue"
    echo "=$r=$newdb somehow already exists. Terminating." >> $LOGFILE
    exit 1
  fi

  echo "=$r=Running DB import to $newdb" >> $LOGFILE
  try mysql -e "create database $newdb"
  try mysql -e "grant all on $newdb.* to $dbuser"
  try mysql -e "flush privileges"
  try mysql "$newdb" < $TEMPDIR/$dbname.sql
  
  rm -f $TEMPDIR/$dbname.sql

  try sed -i "s/DB_NAME', '$dbnmame/DB_NAME', '$newdb/" $NEWP/wp-config.php

  echo "=$r=Running permissions" >> $LOGFILE
  try chown --reference=$OLDP $NEWP
  permissions $NEWP

  echo "=$r=Copy of $OLDN to $NEWN completed" >> $LOGFILE
  echo "copy complete"

  unset dt
  unset dbname
  unset dbuser
  unset newdb
  unset TMP
  unset OLDP
  unset NEWP
  unset OLDN
  unset NEWN

} # END COPY
