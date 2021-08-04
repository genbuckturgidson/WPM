##############
# WPM VERIFY #
##############

function verify() {
  POSIT=();
  while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
	  -s|--scan) SCAN="yes" ;;
	  -m|--md5) HASH="yes" ;;
	  -b|--backup) BACKUP="yes" ;;
	  -r|--replace) REPLACE="yes" ;;
	  -p|--path) DESTDIR="$2" ; shift ;;
	  *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}";

  SCAN="${SCAN:-no}"
  HASH="${HASH:-no}"
  BACKUP="${BACKUP:-no}"
  REPLACE="${REPLACE:-no}"
  DESTDIR="${DESTDIR:-`pwd`}"
  local DATETIME=`date +%Y%m%d.%H%M`
  
  [ -d $DESTDIR ] || echo "directory $DIR does not exist"  
  [ -d $DESTDIR ] || exit 1
  cd $DESTDIR
  
  [ -f wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f wp-config.php ] || exit 1
	
  echo "==WPM VERIFY CALLED ON $DATETIME WITH VERSION $WPMVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  
  echo "==$INSTANCEID==Executing verify on $DESTDIR" | tee -a $LOGFILE
  
  if [ "$BACKUP" == "yes" ]; then
  	backup -p $DESTDIR -s
  fi

  ##################
  # MD5 COMPARISON #
  ##################
  if [ "$HASH" == "yes" ]; then
  	# FIRST, GET THE LOCALLY INSTALLED VERSION
  	local VERSION=`grep '$wp_version =' $DESTDIR/wp-includes/version.php | cut -f 2 -d '=' | cut -f 2 -d "'"`
  	[ -z $VERSION ] && echo "Could not determine the WP version"
  	[ -z $VERSION ] && exit 1
  	
  	echo "==$INSTANCEID==Hash called on WP version $VERSION" | tee -a $LOGFILE
	
  	# MAKE OUR DIRECTORY FOR WORK
  	try mkdir -p $TEMPDIR/verify/$VERSION
	
  	# GET THE VERSION FROM WP
  	try wget -O $TEMPDIR/verify/wordpress.$VERSION.tgz https://wordpress.org/wordpress-$VERSION.tar.gz --no-check-certificate &> /dev/null
  	echo "==$INSTANCEID==Successfully got $TEMPDIR/verify/wordpress.$VERSION.tgz" | tee -a $LOGFILE
	
  	# LET'S EXTRACT IT
  	try tar -xzf $TEMPDIR/verify/wordpress.$VERSION.tgz -C $TEMPDIR/verify/$VERSION/
	
  	# MD5 THE VERSION FROM WP
  	find $TEMPDIR/verify/$VERSION/wordpress/ -type f -exec md5sum {} \; > $TEMPDIR/verify/$VERSION/record.lst
	
  	# MD5 THE VERSION CURRENTLY INSTALLED
  	find . -type f -exec md5sum {} \; > $TEMPDIR/verify/$VERSION/installed.lst

  	while read LINE; do
      RECORD_FIELD_1=`echo $line | cut -f 1 -d ' '`
	    RECORD_FIELD_2=`echo $line | cut -f 2 -d ' '`
	    WP_FILE=`echo $RECORD_FIELD_2 | rev | cut -d '/' -f 1 | rev`
	    INSTALLED_FIELD_1=`grep "$WP_FILE" $TEMPDIR/verify/$VERSION/installed.lst | cut -f 1 -d ' '`
	    INSTALLED_FIELD_2=`grep "$WP_FILE" $TEMPDIR/verify/$VERSION/installed.lst | cut -f 2 -d ' '`
	    if [ "$RECORD_FIELD_1" != "$INSTALLED_FIELD_1" ]; then
	      echo "==$INSTANCEID==$WP_FILE DIFFERENCE DETECTED!" | tee -a $LOGFILE
		    echo "==$INSTANCEID==DEBUG OUTPUT: record $RECORD_FIELD_2; installed $INSTALLED_FIELD_2" | tee -a $LOGFILE
		    echo "==$INSTANCEID==DEBUG OUTPUT: md5 record $RECORD_FIELD_1; md5 installed $INSTALLED_FIELD_1" | tee -a $LOGFILE
		    if [ "$REPLACE" == "yes" ] && [[ ! "${INSTALLED_FIELD_2}" != *"wp-config.php"* ]]; then
		      try cp $RECORD_FIELD_2 ./$INSTALLED_FIELD_2
		      echo "==$INSTANCEID==$RECORD_FIELD_2 replaced $INSTALLED_FIELD_2" | tee -a $LOGFILE
		    fi
	    fi
	  done <$TEMPDIR/verify/$VERSION/record.lst
	  rm -rf $TEMPDIR/verify/$VERSION
  fi # END IF HASH

  ##################
  # VIRUS SCANNING #
  ##################
  if [ "$SCAN" == "yes" ]; then
  	if maldet 1>/dev/null; then
	  try maldet -update
	  echo "==$INSTANCEID==Maldet DB updated" | tee -a $LOGFILE
  	  if [ "$REPLACE" == "yes" ]; then
  	    maldet --config-option scan_clamscan=1,quarantine_hits=1
  		echo "==$INSTANCEID==Maldet config with quarantine" | tee -a $LOGFILE
  	  else
  		maldet --config-option scan_clamscan=1,quarantine_hits=0
  		echo "==$INSTANCEID==Maldet config without quarantine" | tee -a $LOGFILE
  	  fi # END IF REPLACE
  	  maldet -a $DESTDIR
  	  echo "==$INSTANCEID==Maldet run on $DESTDIR" | tee -a $LOGFILE
  	elif [ "$(which maldet)" == "" ]; then
  	  echo "==$INSTANCEID==Maldet could not run, because not installed" | tee -a $LOGFILE
  	fi # END IF MALDET
  fi # END IF SCAN
	
  echo "==$INSTANCEID==Verify complete at `date +%Y%m%d.%H%M`" | tee -a $LOGFILE
}
