#######################
# THE RENAME FUNCTION #
#######################

function rename() {	
  POSIT=();
  while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
      -o|--oldname) OLDNAME=$2; shift;;
      -n|--newname) NEWNAME=$2; shift;;
      -p|--path) DESTDIR=$2; shift;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"
  
  DESTDIR=${DESTDIR:-`pwd`}
  if [ ! -d $DESTDIR ]; then
    echo "$DESTDIR doesn't exist"
    exit 1
  fi

  [ -f wp-config.php ] || echo "This isn't a wordpress installation."
  [ -f wp-config.php ] || exit 1

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM RENAME CALLED ON $DATETIME WITH VERSION $WPVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing rename from $OLDNAME to $NEWNAME" | tee -a $LOGFILE

  local DBNAME=`grep DB_NAME wp-config.php | awk -F "'" '{print $4}'`

  echo "==$INSTANCEID==Database is $DBNAME" | tee -a $LOGFILE

  if mysql "${DBNAME}" >/dev/null 2>&1 </dev/null; then
    echo "==$INSTANCEID==${DBNAME} exists and I have access to it" | tee -a $LOGFILE
  else
    echo "==$INSTANCEID==$DBNAME doesn't exist, or I can't access it. Terminating." | tee -a $LOGFILE
    exit 1
  fi

  echo "==$INSTANCEID==Doing DB transform" | tee -a $LOGFILE
  try mysqldump $DBNAME --single-transaction > ${TEMPDIR}/${DBNAME}.${DATETIME}.sql
  sed -i "s/${OLDNAME}/${NEWNAME}/g" ${TEMPDIR}/${DBNAME}.${DATETIME}.sql
  try 6b4178521b3f/lib/fixserial.sh -o $OLDNAME -n $NEWNAME -f ${TEMPDIR}/${DBNAME}.${DATETIME}.sql
  try mysql "$DBNAME" < $TEMPDIR/${DBNAME}.${DATETIME}.sql
  try rm -fv ${TEMPDIR}/${DBNAME}.${DATETIME}.sql
  echo "==$INSTANCEID==DB transform complete" | tee -a $LOGFILE

  echo "==$INSTANCEID==Commencing file operations." | tee -a $LOGFILE

  try cp -v $DESTDIR/wp-config.php $DESTDIR/.wp-config.php.$DATETIME.bak

  if ! grep -q 'WP_HOME' $DESTDIR/wp-config.php; then
    sed -i "s|\$table_prefix.*$|&\n define( 'WP_HOME', 'https://$NEWNAME' );|" $DESTDIR/wp-config.php
  else
    sed -i "s|^.*WP_HOME.*$|define( 'WP_HOME', 'https://$NEWNAME' );|" $DESTDIR/wp-config.php
  fi

  if ! grep -q 'WP_SITEURL' $DESTDIR/wp-config.php; then
    sed -i "s|\$table_prefix.*$|&\n define( 'WP_SITEURL', 'https://$NEWNAME' );|" $DESTDIR/wp-config.php
  else
    sed -i "s|^.*WP_SITEURL.*$|define( 'WP_HOME', 'https://$NEWNAME' );|" $DESTDIR/wp-config.php
  fi

  WPTHEME=$(mysql -sN -e "select \`option_value\` from $DNNAME.\`wp_options\` where \`option_name\`='template';");

  if [ -f $DESTDIR/wp-content/themes/$WPTHEME/functions.php ]; then
    try cp -v $DESTDIR/wp-content/themes/$WPTHEME/functions.php $DESTDIR/wp-content/themes/$WPTHEME/.functions.php.$DATETIME.bak
    sed -i "s|\<\?php$|&\n update_option( 'siteurl', 'https://$NEWNAME' );|" $DESTDIR/wp-content/themes/$WPTHEME/functions.php
    sed -i "s|\<\?php$|&\n update_option( 'home', 'https://$NEWNAME' );|" $DESTDIR/wp-content/themes/$WPTHEME/functions.php
    REMOVE_LINES="yes"
  else
    printf "%s\n%s\n%s\n%s" '<?php' "update_option( 'siteurl', 'https://$NEWNAME' );" "update_option( 'home', 'https://$NEWNAME' );" '?>' > $DESTDIR/wp-content/themes/$WPTHEME/functions.php
    if [ -f $DESTDIR/wp-content/themes/$WPTHEME/functions.php ]; then
      REMOVE_FILE="yes"
    else
      echo "==$INSTANCEID==Could not create functions.php in $DESTDIR/wp-content/themes/$WPTHEME/" | tee -a $LOGFILE
    fi
  fi

  wget -O/dev/null -q --no-check-certificate https://$NEWNAME;

  if [[ "$REMOVE_LINES" == "yes" ]]; then
    sed -i 's/^update_option.*$//' $DESTDIR/wp-content/themes/$WPTHEME/functions.php
  elif [[ "$REMOVE_FILE" == "yes" ]]; then
    if [ -f $DESTDIR/wp-content/themes/$WPTHEME/functions.php ]; then
      rm -f $DESTDIR/wp-content/themes/$WPTHEME/functions.php
    fi
  fi

  echo "==$INSTANCEID==File operations complete." | tee -a $LOGFILE
  echo "==$INSTANCEID==Rename of $OLDNAME to $NEWNAME complete" | tee -a $LOGFILE

} # END RENAME
