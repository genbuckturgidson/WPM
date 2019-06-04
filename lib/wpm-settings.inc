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

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM SETTINGS CALLED ON $dt WITH VERSION $WPVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing settings on 6b4178521b3f/etc/wpm/wpm.conf" >> $LOGFILE

  try cp -v 6b4178521b3f/etc/wpm/wpm.conf 6b4178521b3f/etc/wpm/wpm.${dt}.bak

  echo "=$r=Backup of wpm.conf made @ 6b4178521b3f/etc/wpm/wpm.${dt}.bak" >> $LOGFILE

  for var in "$@"; do
    match=`echo $var | awk -F '=' '{print $1}'`
    echo "${var}"
    try sed -i "s/^${match}.*/${var}/g" 6b4178521b3f/etc/wpm/wpm.conf
  done

  unset match
  unset dt

} # END SETTINGS
