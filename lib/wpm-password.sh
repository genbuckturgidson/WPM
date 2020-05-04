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
  DURATION=${DURATION:-600s}

  [ -f $DIRECTORY/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $DIRECTORY/wp-config.php ] || exit 1

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM PASSWORD CALLED ON $DATETIME WITH VERSION $WPMVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing password on $DIRECTORY" | tee -a $LOGFILE

  cd $DIRECTORY
  local DATABASENAME=`grep DB_NAME wp-config.php | cut -f 2 -d ',' | cut -f 2 -d "'"`
  echo "==$INSTANCEID==The DB name is $DATABASENAME" | tee -a $LOGFILE

  if mysql "${DATABASENAME}" >/dev/null 2>&1 </dev/null; then
    echo "==$INSTANCEID==${DATABASENAME} exists and I have perms to it" | tee -a $LOGFILE
  else
    echo "==$INSTANCEID==$DATABASENAME does not exist or I do not have access to it. Terminating." | tee -a $LOGFILE
    exit 1
  fi
  
  if [ "$VIEW" == "yes" ]; then
  	echo "==$INSTANCEID==View option selected, -d and -u ignored" | tee -a $LOGFILE
  	try mysql $DATABASENAME -N -e "select \`user_login\` from wp_users where \`user_status\`='0';"
  	exit 0
  fi

  if mysql -e "SELECT EXISTS(SELECT 1 FROM $DATABASENAME.wp_users WHERE user_login='$USERNAME' LIMIT 1)"; then
    local PREVIOUSPASSWORDHASH=`mysql $DATABASENAME -e "select user_pass from wp_users where user_login='$USERNAME' limit 1;" | grep -v grep | grep -v user_pass`
  else
    echo "==$INSTANCEID==The specified user $USERNAME was not found. Terminating." | tee -a $LOGFILE
    exit 1
  fi

  if [ -z $PREVIOUSPASSWORDHASH ];then
    echo "==$INSTANCEID==Previous password is zero length?! Dying." | tee -a $LOGFILE
    exit 1
  fi

  echo "==$INSTANCEID==Encrypted previous password $PREVIOUSPASSWORDHASH" | tee -a $LOGFILE

  local PASSWORD=`openssl rand -hex 10`
  printf "%b%s%b%s%b%s%b" "${RED}" "NOT LOGGED:" "${DEFAULT}" "Temporary password will be" "${CIAN}" "$PASSWORD\n" "${DEFAULT}"

  try mysql -e "use $DATABASENAME; update wp_users set user_pass = MD5('$PASSWORD') where user_login='$USERNAME';"

  echo "==$INSTANCEID==Temporary password has been set @ `date +%Y%m%d.%H%M`" | tee -a $LOGFILE

  if [ ! -z $DURATION ] && [ ! "$DURATION" == "0" ];then
    echo "==$INSTANCEID==Sleeping for $DURATION" | tee -a $LOGFILE
    sleep $DURATION
  elif [ "$DURATION" == "0" ]; then
    echo "==$INSTANCEID==Duration is zero, password will not revert." | tee -a $LOGFILE
  fi

  if [ "$DURATION" != "0" ]; then
    echo "==$INSTANCEID==Reverting the password." | tee -a $LOGFILE
    try mysql -e "use $DATABASENAME; update wp_users set user_pass='$PREVIOUSPASSWORDHASH' where user_login='$USERNAME';"
    echo "==$INSTANCEID==Password reverted @ `date +%Y%m%d.%H%M`" | tee -a $LOGFILE
  fi
  
  echo "==$INSTANCEID==Password function complete." | tee -a $LOGFILE

} # END PASSWORD
