#######################
# THE RENAME FUNCTION #
#######################

function rename() {
	
	POSIT=()

	while [[ $# -gt 0 ]]
	do
		key="$1"
  	case $key in
    	-o|--oldname) OLDN=$2; shift;;
    	-n|--newname) NEWN=$2; shift;;
    	-p|--path) P=$2; shift;;
    	*) echo "$1 not implemented" ; POSIT+=("$1") ;;
    	esac
   	shift
  done
  set -- "${POSIT[@]}"

  if [ "$P" == "`pwd`" ]; then
  	echo "Using current directory"
  else
  	[ -d $P ] || exit 1
  	cd $P
  fi

  [ -f wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f wp-config.php ] || exit 1

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM RENAME CALLED ON $dt WITH VERSION $WPVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing rename from $OLDN to $NEWN" >> $LOGFILE

  echo "doing DB dump"

  local dbname=`grep DB_NAME wp-config.php | awk -F "'" '{print $4}'`

  echo "=$r=Database $dbname being dumped" >> $LOGFILE

  if mysql "${dbname}" >/dev/null 2>&1 </dev/null; then
    echo "${dbname} exists (and I have permission to access it)"
    echo "=$r=DB exists and I have access to it" >> $LOGFILE
  else
    echo "${dbname} does not exist (or I do not have permission to access it)"
    echo "refusing to continue"
    echo "=$r=DB doesn't exist, or I can't access it. Terminating." >> $LOGFILE
    exit 1
  fi

  try mysqldump $dbname --single-transaction > $TEMPDIR/$dbname.sql

  echo "doing find/replace"

  echo "fixing serialized php array values"
  echo "=$r=Running fixserial on $TEMPDIR/$dbname.sql" >> $LOGFILE
  try 6b4178521b3f/lib/fixserial.sh -o $OLDN -n $NEWN -f $TEMPDIR/$dbname.sql

  echo "=$r=changing $OLDN to $NEWN" >> $LOGFILE
  try find . -type f -exec sed -i "s/$OLDN/$NEWN/g" {} +

  echo "doing DB import"
  echo "=$r=Running DB import to $dbname" >> $LOGFILE
  try mysql "$dbname" < $TEMPDIR/$dbname.sql

  echo "removing db dump"
  try rm -fv $dbname.sql

  echo "=$r=Rename of $OLDN to $NEWN complete" >> $LOGFILE
  echo "rename complete"

  unset dt
  unset dbname
  unset TMP
  unset NEWN
  unset OLDN
  unset P

} # END RENAME
