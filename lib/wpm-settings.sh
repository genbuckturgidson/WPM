#########################
# THE SETTINGS FUNCTION #
#########################

function settings() {

  if [[ "$1" == "list" ]]; then
    try egrep -v '^#.*$' 6b4178521b3f/etc/wpm/wpm.conf | egrep -v '^$'
    exit 0
  fi

  [ -z "$1" ] && echo "please provide a setting"
  [ -z "$1" ] && exit 1

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM SETTINGS CALLED ON $DATETIME WITH VERSION $WPVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing settings on 6b4178521b3f/etc/wpm/wpm.conf" | tee -a $LOGFILE

  try cp -v 6b4178521b3f/etc/wpm/wpm.conf 6b4178521b3f/etc/wpm/wpm.${DATETIME}.bak

  echo "==$INSTANCEID==Backup of wpm.conf made @ 6b4178521b3f/etc/wpm/wpm.${DATETIME}.bak" | tee -a $LOGFILE

  for VAR in "$@"; do
    MATCH=`echo $VAR | awk -F '=' '{print $1}'`
    echo "${VAR}"
    try sed -i "s/^${MATCH}.*/${VAR}/g" 6b4178521b3f/etc/wpm/wpm.conf
  done
  
  echo "==$INSTANCEID==Settings function complete." | tee -a $LOGFILE

} # END SETTINGS
