#######################
# THE UPDATE FUNCTION #
#######################

function update() {
  POSIT=();
  while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
      -b|--backup) BACKUP="yes" ;;
      -g|--plugins) PLUGINS="yes" ;;
      -s|--skip-ftp) SKIPFTP="yes" ;;
      -p|--path) DESTDIR=$2 ; shift ;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
	esac
	shift
  done
  set -- "${POSIT[@]}";

  BACKUP="${BACKUP:-no}"
  PLUGINS="${PLUGINS:-no}"
  DESTDIR="${DESTDIR:-`pwd`}"
  SKIPFTP="${SKIPFTP:-no}"
  
  [ -d $DESTDIR ] || exit 1
  cd $DESTDIR
  if [ "${BACKUP}" == "yes" ]; then
    backup --path $DESTDIR --skip-uploads
  fi
  
  [ -f wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f wp-config.php ] || exit 1

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM UPDATE CALLED ON $DATETIME WITH VERSION $WPMVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing update on $DESTDIR" | tee -a $LOGFILE

  echo "==$INSTANCEID==Checking $TEMPDIR/wp-installer" | tee -a $LOGFILE

  [ -d $TEMPDIR/wp-installer ] || mkdir -p $TEMPDIR/wp-installer

  echo "==$INSTANCEID==Removing old versions" | tee -a $LOGFILE
  find $TEMPDIR/wp-installer/ -mtime +1 -name wordpress.latest.tar -exec rm -fv '{}' \;

  if [ -e $TEMPDIR/wp-installer/wordpress.latest.tar ]; then
    echo "==$INSTANCEID==Recent version already present" | tee -a $LOGFILE
  else
    try wget -O $TEMPDIR/wp-installer/wordpress.latest.tar.gz https://wordpress.org/latest.tar.gz --no-check-certificate &> /dev/null
    try touch $TEMPDIR/wp-installer/wordpress.latest.tar.gz
    try gunzip $TEMPDIR/wp-installer/wordpress.latest.tar.gz &> /dev/null
    echo "==$INSTANCEID==Recent version downloaded" | tee -a $LOGFILE
  fi

  if [ ! -e $TEMPDIR/wp-installer/wordpress.latest.tar ]; then
    echo "==$INSTANCEID==Cannot get archive at $TEMPDIR/wp-installer/" | tee -a $LOGFILE
    exit 1
  fi

  if tar -f $TEMPDIR/wp-installer/wordpress.latest.tar -x --strip-components=1; then
    echo "==$INSTANCEID==Extracting Wordpress in $DESTDIR complete" | tee -a $LOGFILE
  else
    echo "==$INSTANCEID==Extracting Wordpress in $DESTDIR failed, trying with legacy tar options" | tee -a $LOGFILE
    if tar -f $TEMPDIR/wp-installer/wordpress.latest.tar -x --strip-path=1; then
      echo "==$INSTANCEID==Extracting Wordpress in $DESTDIR complete" | tee -a $LOGFILE
    else
      echo "==$INSTANCEID==Extracting Wordpress completely failed in $DESTDIR" | tee -a $LOGFILE
      exit 1
    fi
  fi

  if [ "${PLUGINS}" == "yes" ]; then
    6b4178521b3f/lib/updater.pl --wp-path=$DESTDIR
  fi

  if [[ "$SKIPFTP" == "no" ]]; then
    echo "==$INSTANCEID==Running permissions" | tee -a $LOGFILE
    permissions $DESTDIR
  elif
    echo "==$INSTANCEID==Permission setting skipped." | tee -a $LOGFILE
  fi

  echo "==$INSTANCEID==Update complete" | tee -a $LOGFILE

} # END UPDATE
