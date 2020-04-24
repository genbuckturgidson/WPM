#######################
# THE DELETE FUNCTION #
#######################

function delete() {
  POSIT=();
  while [[ $# -gt 0 ]]; do
    KEY="$1"
  	case $KEY in
      -b|--backup) DOBACKUP="yes" ;;
      -p|--path) DIRECTORY=$2 ; shift ;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"

  [ -z $DIRECTORY ] && echo "You must provide a full path"
  [ -z $DIRECTORY ] && exit 1

  [ -d $DIRECTORY ] || echo "directory does not exist"
  [ -d $DIRECTORY ] || exit 1

  [ -f $DIRECTORY/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $DIRECTORY/wp-config.php ] || exit 1

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM DELETE CALLED ON $DATETIME WITH VERSION $WPMVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" >> $LOGFILE
  echo "=$INSTANCEID=Executing delete on $DIRECTORY" >> $LOGFILE

  if [ "$DOBACKUP" == "yes" ];then
    backup -p `pwd`
  else
    echo "==$INSTANCEID==WARNING: BACKUP HAS BEEN DECLINED!" | tee -a $LOGFILE
  fi

  cd $DIRECTORY

  local DBNAME=`grep DB_NAME wp-config.php | cut -f 2 -d ' ' | awk -F "'" '{print $2}'`
  echo "==$INSTANCEID==The DB name is $DBNAME" | tee -a $LOGFILE

  local DBUSER=`grep DB_USER wp-config.php | cut -f 2 -d ' ' | awk -F "'" '{print $2}'`
  echo "==$INSTANCEID==The DB user is $DBUSER" | tee -a $LOGFILE

  if mysql "${DBNAME}" >/dev/null 2>&1 </dev/null; then
    echo "==$INSTANCEID==${DBNAME} exists (and I have permission to access it)" | tee -a $LOGFILE
  else
    echo "==$INSTANCEID==${DBNAME} doesn't exist or I lack access" | tee -a $LOGFILE
  fi

  mysql -e "DELETE FROM mysql.user WHERE \`user\`=\"${DBUSER}\";"
  mysql -e "FLUSH PRIVILEGES;"
  echo "==$INSTANCEID==Database user ${DBUSER} has been deleted" | tee -a $LOGFILE

  mysql -e "DROP DATABASE IF EXISTS ${DBNAME};"
  echo "==$INSTANCEID==Database ${DBNAME} has been dropped" | tee -a $LOGFILE

  cd ..

  try rm -rf $DIRECTORY/*
  try rm -rf $DIRECTORY

  echo "==$INSTANCEID==Removal of document root contents completed." | tee -a $LOGFILE

  echo "==$INSTANCEID==Deletion: $DIRECTORY, $DBNAME, $DBUSER; completed." | tee -a $LOGFILE

} # END DELETE
