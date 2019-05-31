##############
# WPM VERIFY #
##############

function verify() {
	POSIT=()
	while [[ $# -gt 0 ]]
	do
		key="$1"
		case $key in
			-s|--scan) SCAN="y" ;;
			-m|--md5) HASH="y" ;;
			-b|--backup) BACKUP="y" ;;
			-r|--replace) REPLACE="y" ;;
			-p|--path) DIR="$2" ; shift ;;
			*) echo "$1 not implemented" ; POSIT+=("$1") ;;
		esac
		shift
	done
	set -- "${POSIT[@]}"

	SCAN="${SCAN:-n}"
	HASH="${HASH:-n}"
	BACKUP="${BACKUP:-n}"
	REPLACE="${REPLACE:-n}"
	DIR="${DIR:-`pwd`}"
	
	echo "==WPM VERIFY CALLED ON $dt WITH VERSION $WPMVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
	
	if [ "$DIR == "`pwd`" ]; then
  	echo "Using `pwd` as the wordpress path"
  else
  	[ -d $DIR ] || echo "directory $DIR does not exist"  
  	[ -d $DIR ] || exit 1
  	cd $DIR
  fi
  
  echo "=$r=Executing verify on $path" >> $LOGFILE

  [ -f wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f wp-config.php ] || exit 1
  
  if [ "$BACKUP" == "y" ]; then
  	backup -p `pwd` -s
  fi

  ##################
  # MD5 COMPARISON #
  ##################
  if [ "$HASH" == "y" ]; then
  	# FIRST, GET THE LOCALLY INSTALLED VERSION
  	local VERSION=`grep '$wp_version =' $DIR/wp-includes/version.php | cut -f 2 -d '=' | cut -f 2 -d "'"`
  	[ -z $VERSION ] && echo "Could not determine the WP version"
  	[ -z $VERSION ] && exit 1
  	echo "=$r=Hash called on WP version $VERSION" >> $LOGFILE
  	echo "WP $VERSION detected, fetching archive..."
	
  	# MAKE OUR DIRECTORY FOR WORK
  	try mkdir -p $TEMPDIR/verify/$VERSION
	
  	# GET THE VERSION FROM WP
  	try wget -O $TEMPDIR/verify/wordpress.$VERSION.tgz https://wordpress.org/wordpress-$VERSION.tar.gz --no-check-certificate &> /dev/null
  	echo "=$r=Successfully got $TEMPDIR/verify/wordpress.$VERSION.tgz" >> $LOGFILE
	
  	# LET'S EXTRACT IT
  	try tar -xzf $TEMPDIR/verify/wordpress.$VERSION.tgz -C $TEMPDIR/verify/$VERSION/
	
  	# MD5 THE VERSION FROM WP
  	find $TEMPDIR/verify/$VERSION/wordpress/ -type f -exec md5sum {} \; > $TEMPDIR/verify/$VERSION/record.lst
	
  	# MD5 THE VERSION CURRENTLY INSTALLED
  	find . -type f -exec md5sum {} \; > $TEMPDIR/verify/$VERSION/installed.lst

  	while read line; do
			RECORD_FIELD_1=`echo $line | cut -f 1 -d ' '`
			RECORD_FIELD_2=`echo $line | cut -f 2 -d ' '`
			WP_FILE=`echo $RECORD_FIELD_2 | rev | cut -d '/' -f 1 | rev`
			INSTALLED_FIELD_1=`grep "$WP_FILE" $TEMPDIR/verify/$VERSION/installed.lst | cut -f 1 -d ' '`
			INSTALLED_FIELD_2=`grep "$WP_FILE" $TEMPDIR/verify/$VERSION/installed.lst | cut -f 2 -d ' '`
			if [ "$RECORD_FIELD_1" != "$INSTALLED_FIELD_1" ]; then
				echo "$WP_FILE DIFFERENCE DETECTED!"
				echo "DEBUG OUTPUT: record $RECORD_FIELD_2; installed $INSTALLED_FIELD_2" | tee -a $LOGFILE
				echo "DEBUG OUTPUT: md5 record $RECORD_FIELD_1; md5 installed $INSTALLED_FIELD_1" | tee -a $LOGFILE

				if [ "$REPLACE" == "y" ]; then
						cp -v $RECORD_FIELD_2 ./$INSTALLED_FIELD_2
				fi
			fi
		done <$TEMPDIR/verify/$VERSION/record.lst
	fi

	##################
	# VIRUS SCANNING #
	##################
	if [ `maldet` ] && [ "$SCAN" == "y" ]; then
		try maldet -update
		echo "=$r=Maldet DB updated" >> $LOGFILE
		if [ "$REPLACE" == "y" ]; then
			maldet --config-option scan_clamscan=1,quarantine_hits=1
			echo "=$r=Maldet config with quarantine" >> $LOGFILE
		else
			maldet --config-option scan_clamscan=1,quarantine_hits=0
			echo "=$r=Maldet config without quarantine" >> $LOGFILE
		fi
		maldet -a `pwd`
		echo "=$r=Maldet run on `pwd`" >> $LOGFILE
	elif [ ! `maldet` ] && [ "$SCAN" == "y" ]; then
		echo "Cannot scan. Maldet not installed."
		echo "=$r=Maldet could not run, because not installed" >> $LOGFILE
	fi
	
	echo "=$r=Verify complete at `date +%Y%m%d.%H%M`" >> $LOGFILE
	echo "wpm --verify is complete."
	
	exit 0
}