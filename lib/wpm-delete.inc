#######################
# THE DELETE FUNCTION #
#######################

function delete() {

	POSIT=()
	while [[ $# -gt 0 ]]
	do
		key="$1"
  	case $key in
    	-b|--backup) do_backup="y" ;;
    	-p|--path) path=$2 ; shift ;;
    	*) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"

  [ -z $path ] && echo "You must provide a full path"
  [ -z $path ] && exit 1

  [ -d $path ] || echo "directory does not exist"
  [ -d $path ] || exit 1

  [ -f $path/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $path/wp-config.php ] || exit 1

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM DELETE CALLED ON $dt WITH VERSION $WPMVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing delete on $path" >> $LOGFILE

  if [ "$do_backup" == "y" ];then
    backup -p `pwd`
  else
    echo "backup declined."
  fi

  cd $path

  local dbname=`grep DB_NAME wp-config.php | cut -f 2 -d ' ' | awk -F "'" '{print $2}'`
  echo "=$r=The DB name is $dbname" >> $LOGFILE

  local dbuser=`grep DB_USER wp-config.php | cut -f 2 -d ' ' | awk -F "'" '{print $2}'`
  echo "=$r=The DB user is $dbuser" >> $LOGFILE

  if mysql "${dbname}" >/dev/null 2>&1 </dev/null; then
    echo "${dbname} exists (and I have permission to access it)"
  else
    echo "${dbname} does not exist (or I do not have permission to access it)"
    echo "=$r=$dbname doesn't exist or I lack access" >> $LOGFILE
  fi

  mysql -e "DELETE FROM mysql.user WHERE \`user\`=\"$dbuser\";"
  mysql -e "FLUSH PRIVILEGES;"
  echo "=$r=Database user $dbuser has been deleted" >> $LOGFILE

  mysql -e "DROP DATABASE IF EXISTS $dbname;"
  echo "=$r=Database $dbname has been dropped" >> $LOGFILE

  cd ..

  try rm -rf $path/*
  try rm -rf $path

  echo "=$r=Removal of document root contents completed" >> $LOGFILE

  echo "=$r=Delete process has completed" >> $LOGFILE

  echo "Deletion of $path as well as DB $dbname and DB USER $dbuser is complete"

  unset dt
  unset dbname
  unset dbuser
  unset do_backup
  unset path

} # END DELETE
