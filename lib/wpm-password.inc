#########################
# THE PASSWORD FUNCTION #
#########################

function password() {

  while [[ $# -gt 0 ]]
  do
    KEY="$1"
  	case $KEY in
      -d|--duration) DURATION=$2 ; shift ;;
      -u|--username) USERNAME=$2 ; shift ;;
      -v|--view) VIEW="yes" ;;
      -p|--path) DIRECTORY=$2 ; shift ;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done

  DIRECTORY=${DIRECTORY:-`pwd`}
  USERNAME=${USERNAME:-admin}
  VIEW=${VIEW:-no}
  DURATION=${DURATION:-0}

  [ -f $DIRECTORY/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $DIRECTORY/wp-config.php ] || exit 1

  local DT=`date +%Y%m%d.%H%M`

  echo "==WPM TEMPPASS CALLED ON $DT WITH VERSION $WPMVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing temppass on $path" >> $LOGFILE

  cd $DIRECTORY
  local DATABASENAME=`grep DB_NAME wp-config.php | cut -f 2 -d ',' | cut -f 2 -d "'"`
  echo "=$r=The DB name is $DATABASENAME" >> $LOGFILE

  if mysql "${DATABASENAME}" >/dev/null 2>&1 </dev/null; then
    echo "${DATABASENAME} exists (and I have permission to access it)"
    echo "=$r=DB exists and I have perms to it" >> $LOGFILE
  else
    echo "${DATABASENAME} does not exist (or I do not have permission to access it)"
    echo "refusing to continue"
    echo "=$r=DB error on $DATABASENAME. Terminating." >> $LOGFILE
    exit 1
  fi
  
  if [ "$VIEW" == "yes" ]; then
  	echo "View option selected, -d and -u ignored"
  	try mysql $DATABASENAME -N -e "select \`user_login\` from wp_users where \`user_status\`='0';"
  	exit 0
  fi

  if mysql -e "SELECT EXISTS(SELECT 1 FROM $DATABASENAME.wp_users WHERE user_login='$USERNAME' LIMIT 1)"; then
    local PREVIOUSPASSWORDHASH=`mysql $DATABASENAME -e "select user_pass from wp_users where user_login='$USERNAME' limit 1;" | grep -v grep | grep -v user_pass`
  else
    echo "The user $USERNAME was not found, refusing to continue"
    echo "=$r=The specified user $USERNAME was not found. Terminating." >> $LOGFILE
    exit 1
  fi

  if [ -z $PREVIOUSPASSWORDHASH ];then
    echo "something's wrong. refusing to continue."
    echo "=$r=Prevpass issue detected. Dying." >> $LOGFILE
    exit 1
  fi

  echo "=$r=Got the previous user password $PREVIOUSPASSWORDHASH" >> $LOGFILE
  echo "user password retrieval found: $PREVIOUSPASSWORDHASH"

  local PASSWORD=`openssl rand -hex 10`
  echo "temporary password will be $PASSWORD"

  try mysql -e "use $DATABASENAME; update wp_users set user_pass = MD5('$PASSWORD') where user_login='$USERNAME';"

  echo "=$r=Temporary password has been set" >> $LOGFILE

  if [ ! -z $DURATION ] && [ ! "$DURATION" == "0" ];then
    echo "=$r=Sleeping for $DURATION" >> $LOGFILE
    echo "sleeping for $DURATION"
    sleep $DURATION
  elif [ "$DURATION" == "0" ]; then
    echo "=$r=duration zero, do not revert" >> $LOGFILE
    echo "duration set to zero, meaning no reverting to old pass"
    echo "if this was in error, the old hashed pass is in the log"
    NOREVERT="1"
  else
    echo "=$r=No duration provided, default to 10 minutes" >> $LOGFILE
    echo "no duration provided, defaulting to 10 minutes"
    sleep 600
  fi

  if [ ! -z $NOREVERT ]; then
    echo "reverting password"
    echo "=$r=Reverting the password" >> $LOGFILE
    try mysql -e "use $DATABASENAME; update wp_users set user_pass='$PREVIOUSPASSWORDHASH' where user_login='$USERNAME';"
    echo "=$r=password has been reverted" >> $LOGFILE
    echo "password reverted"
  fi

} # END PASSWORD
