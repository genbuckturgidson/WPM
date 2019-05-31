#######################
# THE UPDATE FUNCTION #
#######################

function update() {

	POSIT=()
	while [[ $# -gt 0 ]]
	do
		key="$1"
		case $key in
			-b|--backup) backup="y" ;;
			-g|--plugins) do_plugins="y" ;;
			-p|--path) path=$2 ; shift ;;
			*) echo "$1 not implemented" ; POSIT+=("$1") ;;
		esac
		shift
	done
	set -- "${POSIT[@]}"

  path="${path:-`pwd`}"
  
  if [ "$path" == "`pwd`" ]; then
  	echo "Using `pwd`"
  else
  	[ -d $path ] || exit 1
  	cd $path
  fi

  if [ "${backup}" == "y" ]; then
    backup --path $path --skip-uploads
  fi

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM UPDATE CALLED ON $dt WITH VERSION $WPMVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing update on $path" >> $LOGFILE

  [ -f wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f wp-config.php ] || exit 1

  echo "getting recent wordpress version"

  echo "=$r=Checking $TEMPDIR/installer" >> $LOGFILE

  [ -d $TEMPDIR/installer ] || mkdir -p $TEMPDIR/installer

  echo "=$r=Removing old versions" >> $LOGFILE
  find $TEMPDIR/installer/ -mtime +1 -name wordpress.latest.tar -exec rm -fv '{}' \;

  if [ -e $TEMPDIR/installer/wordpress.latest.tar ]; then
    echo "=$r=Recent version already present" >> $LOGFILE
  else
    try wget -O $TEMPDIR/installer/wordpress.latest.tar.gz https://wordpress.org/latest.tar.gz --no-check-certificate &> /dev/null
    gunzip $TEMPDIR/installer/wordpress.latest.tar.gz &> /dev/null
    echo "=$r=Recent version downloaded" >> $LOGFILE
  fi

  if [ ! -e $TEMPDIR/installer/wordpress.latest.tar ]; then
    echo "=$r=Cannot get archive at $TEMPDIR/installer/" >> $LOGFILE
    echo "can't get archive at $TEMPDIR/installer/" && exit 1
  fi

  echo ="$r"=Extracting Wordpress in `pwd` >> $LOGFILE

  if tar -f $TEMPDIR/installer/wordpress.latest.tar -x --strip-components=1; then
    echo "=$r=Extracting Wordpress in `pwd` complete" >> $LOGFILE
  else
    echo "=$r=Extracting Wordpress in `pwd` failed, trying with legacy tar options" >> $LOGFILE
    if tar -f $TEMPDIR/installer/wordpress.latest.tar -x --strip-path=1; then
      echo "=$r=Extracting Wordpress in `pwd` complete" >> $LOGFILE
    else
      echo "=$r=Extracting Wordpress completely failed in `pwd`" >> $LOGFILE
      exit 1
    fi
  fi

  if [ "${do_plugins}" == "y" ]; then
    6b4178521b3f/lib/updater.pl --wp-path=$path
  fi

  echo "running permissions"
  echo "=$r=Running permissions" >> $LOGFILE
  permissions $path

  echo "Update complete"
  echo "=$r=Update complete" >> $LOGFILE

  unset dt
  unset path
  unset backup
  unset do_plugins

} # END UPDATE
