#########################
# THE PASSWORD FUNCTION #
#########################

function password() {

	POSIT=()
	while [[ $# -gt 0 ]]
	do
		key="$1"
  	case $key in
    	-d|--duration) duration=$2 ; shift ;;
    	-u|--username) username=$2 ; shift ;;
    	-v|--view) VIEW="yes" ;;
    	-p|--path) path=$2 ; shift ;;
    	*) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"

	path="${path:-`pwd`}"
	username="${username:-admin}"

  [ -f $path/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $path/wp-config.php ] || exit 1

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM TEMPPASS CALLED ON $dt WITH VERSION $WPMVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing temppass on $path" >> $LOGFILE

  cd $path
  local dbname=`grep DB_NAME wp-config.php | cut -f 2 -d ' ' | awk -F "'" '{print $2}'`
  echo "=$r=The DB name is $dbname" >> $LOGFILE

  if mysql "${dbname}" >/dev/null 2>&1 </dev/null; then
    echo "${dbname} exists (and I have permission to access it)"
    echo "=$r=DB exists and I have perms to it" >> $LOGFILE
  else
    echo "${dbname} does not exist (or I do not have permission to access it)"
    echo "refusing to continue"
    echo "=$r=DB error on $dbname. Terminating." >> $LOGFILE
    exit 1
  fi
  
  if [ "$VIEW" == "yes" ]; then
  	echo "View option selected, -d and -u ignored"
  	try mysql $dbname -e "select `user_login` from wp_users where `disabled`='0' or `user_status`='0'\G"
  	exit 0
  fi

  if mysql -e "SELECT EXISTS(SELECT 1 FROM $dbname.wp_users WHERE user_login='$username' LIMIT 1)"; then
    local prevpass=`mysql -e "use $dbname; select user_pass from wp_users where user_login='$username' limit 1;" | grep -v grep | grep -v user_pass`
  else
    echo "The user $username was not found, refusing to continue"
    echo "=$r=The specified user $username was not found. Terminating." >> $LOGFILE
    exit 1
  fi

  if [ -z $prevpass ];then
    echo "something's wrong. refusing to continue."
    echo "=$r=Prevpass issue detected. Dying." >> $LOGFILE
    exit 1
  fi

  echo "=$r=Got the previous user password $prevpass" >> $LOGFILE
  echo "user password retrieval found: $prevpass"

  local password=`openssl rand -hex 10`
  echo "temporary password will be $password"

  try mysql -e "use $dbname; update wp_users set user_pass = MD5('$password') where user_login='$username';"

  echo "=$r=Temporary password has been set" >> $LOGFILE

  if [ ! -z $duration ] && [ ! "$duration" == "0" ];then
    echo "=$r=Sleeping for $duration" >> $LOGFILE
    echo "sleeping for $duration"
    sleep $duration
  elif [ "$duration" == "0" ]; then
    echo "=$r=duration zero, do not revert" >> $LOGFILE
    echo "duration set to zero, meaning no reverting to old pass"
    echo "if this was in error, the old hashed pass is in the log"
    norevert="1"
  else
    echo "=$r=No duration provided, default to 10 minutes" >> $LOGFILE
    echo "no duration provided, defaulting to 10 minutes"
    sleep 600
  fi

  if [ ! -z $norevert ]; then
    echo "reverting password"
    echo "=$r=Reverting the password" >> $LOGFILE
    try mysql -e "use $dbname; update wp_users set user_pass='$prevpass' where user_login='$username';"
    echo "=$r=password has been reverted" >> $LOGFILE
    echo "password reverted"
  fi

  unset username
  unset duration
  unset dt
  unset dbname
  unset prevpass
  unset password
  unset path

} # END PASSWORD
