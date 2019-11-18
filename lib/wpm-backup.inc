#######################
# THE BACKUP FUNCTION #
#######################

function backup() {

	POSIT=()
	while [[ $# -gt 0 ]]
	do
		key="$1"
		case $key in
			-n|--no-compress) no_compress="y" ;;
			-d|--delete-old) delete_old="y" ;;
			-s|--skip-uploads) skip_uploads="y" ;;
			-p|--path) path="$2" ; shift ;;
			*) echo "$1 not implemented" ; POSIT+=("$1") ;;
		esac
		shift
	done
	set -- "${POSIT[@]}"

	no_compress="${no_compress:-n}"
	delete_old="${delete_old:-n}"
	skip_uploads="${skip_uploads:-n}"
	path="${path:-`pwd`}"

  [ -f $path/wp-config.php ] || echo "this isn't a wordpress installation"
  [ -f $path/wp-config.php ] || exit 1

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM BACKUP CALLED ON $dt WITH VERSION $WPMVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing backup on $path" >> $LOGFILE

  cd $path

  local name=`echo $path | rev | cut -d '/' -f 1 | rev`

  if [ "$name" == "" ] || [ ${#name} -lt 3 ]; then
    name="wordpress"
  fi

  echo "=$r=The name is $name" >> $LOGFILE

  local dbname=`grep DB_NAME wp-config.php | awk -F "'" '{print $4}'`
  echo "=$r=The DB name is $dbname" >> $LOGFILE

  if mysql "${dbname}" >/dev/null 2>&1 </dev/null; then
    echo "${dbname} exists (and I have permission to access it)"
  else
    echo "${dbname} does not exist (or I do not have permission to access it)"
    echo "=$r=$dbname doesn't exist or I lack access, terminating" >> $LOGFILE
    exit 1
  fi

  echo "=$r=Starting the DB dump" >> $LOGFILE
  try mysqldump $dbname --single-transaction > $TEMPDIR/$dbname.$dt.sql

  echo "=$r=The database dump is complete." >> $LOGFILE
  echo "The Database dump is complete."

  if [ "$BACKUPPATH" == "PARENTOFGIVEN" ]; then
    BACKUPPATH=`dirname $path`
    delete_old="n"
  fi

  if [ "$delete_old" == "y" ]; then
    try find $BACKUPPATH -mtime +1 -type f -exec rm -fv '{}' \;;
    echo "=$r=removed old backups" >> $LOGFILE;
  fi

  echo "Checking space."

  local sf=`echo $(($(stat -f --format="%a*%S" .)))`;
  local sn=`du -sb .|awk '{print $1}'`;
  local sb=${sn}
  local sn=`echo $((sn + sn))`;

  if [ $sf -gt $sn ]; then
    echo "$sf is available and $sn is needed. Proceeding..."
    echo "=$r=Adequate free space detected" >> $LOGFILE
  else
    echo "$sf is available, but $sn is needed. Terminating"
    echo "=$r=Insufficient space available. Terminating" >> $LOGFILE
    exit 1
  fi

  echo "=$r=Starting the archive creation" >> $LOGFILE
  echo "Starting the archive creation"

  [ `which xz` ] && compressor="xz"
  [ `which pv` ] && progress="pv"
  
  if [ "$progress" == "pv" ]; then
  	tar_options="cf"
  	intermediate_pred="pv -per -s${sb} |"
  else
  	tar_options="cfv"
  	intermediate_pred=""
  fi
  
  if [ "$skip_uploads" == "y" ]; then
  	excludes="--exclude=wp-content/uploads"
  else
  	excludes=""
  fi
  
  if [ "$no_compress" == "y" ]; then
  	if [ "$compressor" == "xz" ]; then
  		pred="xz -0 > $BACKUPPATH/$name.$dt.tar.xz"
  	else
  		pred="gzip -1 > $BACKUPPATH/$name.$dt.tar.gz"
  	fi
  else
  	if [ "$compressor" == "xz" ]; then
  		pred="xz -9 > $BACKUPPATH/$name.$dt.tar.xz"
  	else
  		pred="gzip -9 > $BACKUPPATH/$name.$dt.tar.gz"
  	fi
  fi
  
  [ `which getfacl` ] && getfacl -R `pwd` > permissions_backup.${dt}
  [ `which getfacl` ] && echo "permissions backup completed."
  [ `which getfacl` ] && echo "the backup can be restored with setfacl --restore=${1}/.permissions_backup.${dt}"

  CMD="try tar $tar_options - ./* $TEMPDIR/$dbname.$dt.sql $excludes | $intermediate_pred $pred"
  
  eval $CMD

  rm -f $TEMPDIR/$dbname.$dt.sql

  echo "=$r=Archive created $name.$dt.tar.xz" >> $LOGFILE
  echo "The archive is available at $BACKUPPATH/$name.$dt.tar.xz"

  unset sn
  unset sf
  unset sb
  unset dt
  unset name
  unset dbname
  unset path
  unset no_compress
  unset skip_uploads
  unset delete_old
  unset compressor
  unset progress

} # END BACKUP
