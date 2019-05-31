############################
# THE PERMISSIONS FUNCTION #
############################

function permissions() {

  [ -z "$1" ] && echo "You must give a full path $1"
  [ -z "$1" ] && exit 1

  [ -d $1 ] || echo "directory $1 does not exist"
  [ -d $1 ] || exit 1

  [ -f $1/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $1/wp-config.php ] || exit 1

  local dt=`date +%Y%m%d.%H%M`

  [ `which getfacl` ] && getfacl -R $1 > .permissions_backup.${dt}
  [ `which getfacl` ] && echo "permissions backup completed."
  [ `which getfacl` ] && echo "the backup can be restored with setfacl --restore=${1}/.permissions_backup.${dt}"

  echo "==WPM PERMISSIONS CALLED ON $dt WITH VERSION $WPMVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing permissions on $1" >> $LOGFILE

  echo "=$r=Ensuring the uploads directory exists" >> $LOGFILE
  [ -d "$1/wp-content/uploads" ] || mkdir -p $1/wp-content/uploads

  echo "=$r=Setting file and directory permissions" >> $LOGFILE
  try find $1 -type d -exec chmod 750 '{}' \;
  try find $1 -type f -exec chmod 640 '{}' \;

  echo "=$r=setting ownership" >> $LOGFILE

  [ -z $SELECTED_USER ] && uid="9001" || uid=`id -u -n $SELECTED_USER`

  # THE UIDS WE KNOW WE SHOULDNT BE USING
  local badness=("0" "2" "3" "4" "5" "6" "7" "8" "9" "10" "13" "34" "38" "39" "41" "65534" "100")
  for baddy in ${badness[*]}
  do
    if [ "$uid" == "$baddy" ]; then
      echo "UID of $baddy is not allowed setting to over nine thousand"
      uid="9001"
    fi
  done # END BADNESS CHECK
  try chown -R `id -u -n $uid`:`getent group $SELECTED_GROUP | cut -d: -f1` $1

  local fpmcheck=`ps -ef | grep fpm | grep -v grep`
  local apachecheck=`ps -ef | egrep 'apache|httpd|apache2' | grep -v egrep | grep -v grep`

  if [ ${#fpmcheck} -eq 0 ]; then
    if [ ${#apachecheck} -gt 0 ]; then
      echo "php_flag engine off" > $1/wp-content/uploads/.htaccess
      echo "=$r=Wrote htaccess file to uploads (mod_php style)" >> $LOGFILE
      try find $1/wp-content/uploads/ -type d -exec chmod 770 '{}' \;
      echo "=$r=uploads directory set 770" >> $LOGFILE
    fi
  elif [ ${#fpmcheck} -gt 0 ]; then
    if [ ${#apachecheck} -gt 0 ]; then
      echo "Options -ExecCGI" > $1/wp-content/uploads/.htaccess
      echo "=$r=Wrote htaccess file to uploads (fpm style)" >> $LOGFILE
      try find $1/wp-content/uploads/ -type d -exec chmod 770 '{}' \;
      echo "=$r=uploads directory set 770" >> $LOGFILE
    fi
  else
    echo "Apache isn't running, skipping htaccess"
    echo "=$r=Apache not detected, skipping htaccess and uploads dir" >> $LOGFILE
    echo "You may need to run find $1/wp-content/uploads/ -type d -exec chmod 770 '{}' \\;"
  fi

  echo "=$r=checking special directories" >> $LOGFILE

  [ -d "$1/wp-content/cache" ] && find $1/wp-content/cache -type d -exec chmod 770 '{}' \;
  [ -d "$1/wp-content/w3tc-config" ] && find $1/wp-content/w3tc-config -type d -exec chmod 770 '{}' \;
  [ -d "$1/cache" ] && find $1/cache -type d -exec chmod 770 '{}' \;
  [ -d "$1/w3tc-config" ] && find $1/w3tc-config -type d -exec chmod 770 '{}' \;
  [ -d "$1/stats" ] && chown -R stats $1/stats
  [ -d "$1/wp-content/wflogs" ] && find $1/wp-content/wflogs -type d -exec chmod 770 '{}' \;
  [ -d "$1/wp-content/wfcache" ] && find $1/wp-content/wfcache -type d -exec chmod 770 '{}' \;
  [ -d "$1/wp-content/wflogs" ] && find $1/wp-content/wflogs -type f -exec chmod 660 '{}' \;

  echo "Permission set completed"
  echo "=$r=permissions set completed." >> $LOGFILE

  unset dt
  unset fpmcheck
  unset apachecheck
  unset uid
  unset badness
  unset baddy

} # END PERMISSIONS
