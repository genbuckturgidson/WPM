#######################
# THE MANGLE FUNCTION #
#######################

mangle() {

	POSIT=()
	while [[ $# -gt 0 ]]
	do
		key="$1"
  	case $key in
  	  -n|--no-backup) no_backup="y" ;;
  	  -p|--path) path=$2 ; shift ;;
  	  -s|--skip-search) skip_search="y" ;;
  	  *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"

	path="${path:-/}"
  [ -d $path ] || path="/"

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM MANGLE CALLED ON $dt WITH VERSION $WPVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing mangle on $path" >> $LOGFILE

  if [ "$skip_search" == "y" ]; then
  	[ -f $TEMPDIR/wordpress_installs.list ] || echo "No wordpress_installs.list found"
  	exit 1
  else
  	search $path
  fi

  while read line
  do
  	if [ ! $no_backup == "y" ]; then
  		backup --path $line --skip-uploads
  	fi
    update --path $line --plugins
  done < $TEMPDIR/wordpress_installs.list

  unset skip_search
  unset path
  unset no_backup

} # END MANGLE
