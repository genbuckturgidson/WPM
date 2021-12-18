#######################
# THE MANGLE FUNCTION #
#######################

mangle() {
  POSIT=();
  while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
      -n|--no-backup) BACKUP="no" ;;
      -p|--path) DESTDIR=$2 ; shift ;;
      -s|--skip-search) SKIPSEARCH="yes" ;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}";

  SKIPSEARCH="${SKIPSEARCH:-no}"
  BACKUP="${BACKUP:-yes}"
  DESTDIR="${DESTDIR:-/}"
  [ -d $DESTDIR ] || DESTDIR="/"
  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM MANGLE CALLED ON $DATETIME WITH VERSION $WPVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing mangle on $DESTDIR" | tee -a $LOGFILE

  if [ "$SKIPSEARCH" == "yes" ]; then
  	[ -f $TEMPDIR/wordpress_installs.list ] || echo "==$INSTANCEID==$TEMPDIR/wordpress_installs.list not found." | tee -a $LOGFILE
  	exit 1
  else
  	search $DESTDIR
  fi

  while read LINE
  do
  	if [ "$BACKUP" == "yes" ]; then
  		backup --path $LINE --skip-uploads
  	fi
    update --path $LINE --plugins
  done < $TEMPDIR/wordpress_installs.list

} # END MANGLE
