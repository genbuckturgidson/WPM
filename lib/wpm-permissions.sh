############################
# THE PERMISSIONS FUNCTION #
############################

function permissions() {

  DESTDIR="$1"; DESTDIR=${DESTDIR:-`pwd`}
  [ -d $DESTDIR ] || echo "Directory $DESTDIR does not exist."
  [ -d $DESTDIR ] || exit 1

  [ -f $DESTDIR/wp-config.php ] || echo "This isn't a wordpress installation"
  [ -f $DESTDIR/wp-config.php ] || exit 1

  local $DATETIME=`date +%Y%m%d.%H%M`
  
  if [ `which getfacl` ]; then
    getfacl -R $DESTDIR > .permissions_backup.${DATETIME}
    echo "To rollback: setfacl --restore=${DESTDIR}/.permissions_backup.${DATETIME}"
  fi

  echo "==WPM PERMISSIONS CALLED ON $DATETIME WITH VERSION $WPMVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing permissions on $DESTDIR" | tee -a $LOGFILE

  echo "==$INSTANCEID==Ensuring the uploads directory exists" | tee -a $LOGFILE
  [ -d "$DESTDIR/wp-content/uploads" ] || mkdir -p $DESTDIR/wp-content/uploads

  echo "==$INSTANCEID==Setting file and directory permissions" | tee -a $LOGFILE
  try find $DESTDIR -type d -exec chmod 750 '{}' \;
  try find $DESTDIR -type f -exec chmod 640 '{}' \;

  echo "==$INSTANCEID==Setting ownership" | tee -a $LOGFILE

  [ -z $SELECTED_USER ] && UID="9001" || UID=`id -u -n $SELECTED_USER`

  # THE UIDS WE KNOW WE SHOULDNT BE USING
  local BADNESS=("0" "2" "3" "4" "5" "6" "7" "8" "9" "10" "13" "34" "38" "39" "41" "65534" "100")
  for BADDY in ${BADNESS[*]}; do
    if [ "$UID" == "$BADDY" ]; then
      echo "UID of $BADDY is not allowed setting to over nine thousand"
      UID="9001"
    fi
  done # END BADNESS CHECK
  
  echo "==$INSTANCEID==User: `id -u -n $UID`, Group: `getent group $SELECTED_GROUP | cut -d: -f1`" | tee -a $LOGFILE
  try chown -R `id -u -n $UID`:`getent group $SELECTED_GROUP | cut -d: -f1` $DESTDIR

  local FPMCHECK=`ps -ef | grep fpm | grep -v grep`
  local APACHECHECK=`ps -ef | egrep 'apache|httpd|apache2' | grep -v egrep | grep -v grep`

  if [ ${#FPMCHECK} -eq 0 ]; then
    if [ ${#APACHECHECK} -gt 0 ]; then
      echo "php_flag engine off" > $DESTDIR/wp-content/uploads/.htaccess
      echo "==$INSTANCEID==Wrote htaccess file to uploads (mod_php style)" | tee -a $LOGFILE
      try find $DESTDIR/wp-content/uploads/ -type d -exec chmod 770 '{}' \;
      echo "==$INSTANCEID==Uploads directory set 770" | tee -a $LOGFILE
    fi
  elif [ ${#FPMCHECK} -gt 0 ]; then
    if [ ${#APACHECHECK} -gt 0 ]; then
      echo "Options -ExecCGI" > $DESTDIR/wp-content/uploads/.htaccess
      echo "==$INSTANCEID==Wrote htaccess file to uploads (fpm style)" | tee -a $LOGFILE
      try find $DESTDIR/wp-content/uploads/ -type d -exec chmod 770 '{}' \;
      echo "==$INSTANCEID==Uploads directory set 770" | tee -a $LOGFILE
    fi
  else
    echo "==$INSTANCEID==Apache not running, no htaccess written." | tee -a $LOGFILE
  fi

  echo "==$INSTANCEID==Checking special directories." | tee -a $LOGFILE

  [ -d "$DESTDIR/wp-content/cache" ] && find $DESTDIR/wp-content/cache -type d -exec chmod 770 '{}' \;
  [ -d "$DESTDIR/wp-content/w3tc-config" ] && find $DESTDIR/wp-content/w3tc-config -type d -exec chmod 770 '{}' \;
  [ -d "$DESTDIR/cache" ] && find $DESTDIR/cache -type d -exec chmod 770 '{}' \;
  [ -d "$DESTDIR/w3tc-config" ] && find $DESTDIR/w3tc-config -type d -exec chmod 770 '{}' \;
  [ -d "$DESTDIR/stats" ] && chown -R stats $DESTDIR/stats
  [ -d "$DESTDIR/wp-content/wflogs" ] && find $DESTDIR/wp-content/wflogs -type d -exec chmod 770 '{}' \;
  [ -d "$DESTDIR/wp-content/wfcache" ] && find $DESTDIR/wp-content/wfcache -type d -exec chmod 770 '{}' \;
  [ -d "$DESTDIR/wp-content/wflogs" ] && find $DESTDIR/wp-content/wflogs -type f -exec chmod 660 '{}' \;

  echo "==$INSTANCEID==Permissions set complete." | tee -a $LOGFILE

} # END PERMISSIONS
