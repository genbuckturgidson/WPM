########################
# THE INSTALL FUNCTION #
########################

function install() {
  POSIT=();
  while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
      -d|--domain) DOMAIN="$2"; shift;;
      -p|--path) DESTDIR="$2"; shift;;
      *) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"

  DESTDIR="${DESTDIR:-`pwd`}"
  local DATETIME=`date +%Y%m%d.%H%M`

  [ -z $DOMAIN ] && echo "you must provide a domain name"
  [ -z $DOMAIN ] && exit 1

  [ -f "$DESTDIR/wp-config.php" ] && echo "this is already a wordpress installation"
  [ -f "$DESTDIR/wp-config.php" ] && exit 1

  [ -d "$DESTDIR/wp-content" ] && echo "this is already a wordpress installation"
  [ -d "$DESTDIR/wp-content" ] && exit 1

  echo "==WP INSTALL CALLED ON $DATETIME WITH VERSION $WPVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==starting install in $DESTDIR==" | tee -a $LOGFILE

  cd $DESTDIR
  
  local PASSWORD=`openssl rand -hex 5`
  local TRIMMEDDOMAIN=`echo $DOMAIN | sed -e 's/\.//g' | tr '-' '_'| cut -c -10`
  local TRIMMEDDOMAIN+=`openssl rand -hex 2`
  echo "==$INSTANCEID==Password and seed have been generated" | tee -a $LOGFILE

  echo "==$INSTANCEID==Checking $TEMPDIR/wp-installer" | tee -a $LOGFILE
  [ -d $TEMPDIR/wp-installer ] || try mkdir -p $TEMPDIR/wp-installer
  try chmod 1777 $TEMPDIR/wp-installer

  echo "==$INSTANCEID==Removing old versions if they exist" | tee -a $LOGFILE
  try find $TEMPDIR/wp-installer/ -mtime +1 -iname "wordpress.latest*" -delete

  if [ -e $TEMPDIR/wp-installer/wordpress.latest.tar ]; then
    echo "==$INSTANCEID==Recent version already present" | tee -a $LOGFILE
  else
    try wget -O $TEMPDIR/wp-installer/wordpress.latest.tar.gz https://wordpress.org/latest.tar.gz --no-check-certificate &> /dev/null
    try gunzip $TEMPDIR/wp-installer/wordpress.latest.tar.gz &> /dev/null
    if [ -e $TEMPDIR/wp-installer/wordpress.latest.tar ]; then
      try touch $TEMPDIR/wp-installer/wordpress.latest.tar
    else
      echo "==$INSTANCEID==tar ball of wp not present?!" | tee -a $LOGFILE
      exit 1
    fi
    echo "==$INSTANCEID==Recent version downloaded" | tee -a $LOGFILE
  fi

  if [ ! -e $TEMPDIR/wp-installer/wordpress.latest.tar ]; then
    echo "==$INSTANCEID==Cannot get archive at $TEMPDIR/wp-installer/" | tee -a $LOGFILE
    exit 1
  fi

  echo "==$INSTANCEID==Extracting Wordpress in $DESTDIR" | tee -a $LOGFILE

  if tar -f $TEMPDIR/wp-installer/wordpress.latest.tar -x --strip-components=1; then
    echo "==$INSTANCEID==Extracting Wordpress in $DESTDIR complete" | tee -a $LOGFILE
  else
    echo "==$INSTANCEID==Extracting Wordpress in $INSTANCEID failed, trying with legacy tar options" | tee -a $LOGFILE
    if tar -f $TEMPDIR/wp-installer/wordpress.latest.tar -x --strip-path=1; then
      echo "==$INSTANCEID==Extracting Wordpress in $DESTDIR complete" | tee -a $LOGFILE
    else
      echo "==$INSTANCEID==Extracting Wordpress completely failed in $DESTDIR" | tee -a $LOGFILE
      exit 1
    fi
  fi

  echo "==$INSTANCEID==Generating configuration" | tee -a $LOGFILE

  echo -e "<?php\ndefine('DB_NAME', 'database_name_here');\ndefine('DB_USER', 'username_here');\ndefine('DB_PASSWORD', 'password_here');\ndefine('DB_HOST', 'localhost');\ndefine('DB_CHARSET', 'utf8');\ndefine('DB_COLLATE', '');\n"| sed -e "s/database_name_here/""$TRIMMEDDOMAIN""/g" | sed -e "s/username_here/""$TRIMMEDDOMAIN""/g" | sed -e "s/password_here/""$PASSWORD""/g" > wp-config.php

  try wget -O - -q https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php

  echo "==$INSTANCEID==Adding ftp user $TRIMMEDDOMAIN==" | tee -a $LOGFILE

  [ -z $SELECTED_USER ] && UID="9001" || UID=`id -n $SELECTED_USER`

  # THE UIDS WE KNOW WE SHOULDNT BE USING
  local BADNESS=("0" "2" "3" "4" "5" "6" "7" "8" "9" "10" "13" "34" "38" "39" "41" "65534" "100")
  for BADDY in ${BADNESS[*]}
  do
    if [ $UID -eq $BADDY ]; then
      echo "UID of $BADDY is not allowed setting to over nine thousand"
      uid="9001"
    fi
  done # END BADNESS CHECK

  try useradd $TRIMMEDDOMAIN -u $UID -g $SELECTED_GROUP -d $DESTDIR -s /bin/sh -p $(openssl passwd -1 $PASSWORD) -o
  echo "==$INSTANCEID==FTP user added" | tee -a $LOGFILE

  echo "define('FS_METHOD', 'ftpsockets');" >> wp-config.php
  echo "define('FTP_USER', '$TRIMMEDDOMAIN');" >> wp-config.php
  echo "define('FTP_PASS', '$PASSWORD');" >> wp-config.php
  echo "define('FTP_HOST', '127.0.0.1');" >> wp-config.php
  echo "==$INSTANCEID==FTP details and FS_METHOD added to config" | tee -a $LOGFILE

  echo -e "\$table_prefix = 'wp_';\n\ndefine ('WPLANG', '');\ndefine('WP_DEBUG', false);\nif ( ! defined('ABSPATH') )\ndefine('ABSPATH', dirname(__FILE__) . '/');\nrequire_once(ABSPATH . 'wp-settings.php');" >> wp-config.php

  local DATABASES=`mysql -e "show databases like '$TRIMMEDDOMAIN'" | wc -l`
  if [ "$DATABASES" -lt 1 ]; then
    echo "==$INSTANCEID==Creating database $TRIMMEDDOMAIN" | tee -a $LOGFILE
    echo "create database $TRIMMEDDOMAIN" | mysql

    echo "==$INSTANCEID==Granting permissions on $TRIMMEDDOMAIN to $TRIMMEDDOMAIN@localhost" | tee -a $LOGFILE
    echo "grant all on $TRIMMEDDOMAIN.* to '$TRIMMEDDOMAIN'@'localhost' identified by '$PASSWORD'" | mysql
  else
    echo "==$INSTANCEID==Database $TRIMMEDDOMAIN already exists" | tee -a $LOGFILE
    exit 1
  fi

  local DATABASES=`mysql -e "show databases like '$TRIMMEDDOMAIN'" | wc -l`
  if [ "$DATABASES" -lt 1 ]; then
    echo "==$INSTANCEID==Database creation failed. Terminating." | tee -a $LOGFILE
    exit 1
  fi

  echo "==$INSTANCEID==Setting Permissions on $DESTDIR" | tee -a $LOGFILE
  try mkdir $DESTDIR/wp-content/uploads
  GROUP="`getent group $SELECTED_GROUP | cut -d ':' -f 1`"
  echo "==$INSTANCEID==User: $TRIMMEDDOMAIN, group: $GROUP" | tee -a $LOGFILE
  try chown -R $TRIMMEDDOMAIN:$GROUP $DESTDIR
  try find $DESTDIR -type d -exec chmod 750 '{}' \;
  try find $DESTDIR -type f -exec chmod 640 '{}' \;

  [ -d $DESTDIR/wp-content/uploads ] && try chmod 770 $DESTDIR/wp-content/uploads || try install -d -m 0770 $DESTDIR/wp-content/uploads

  local FPMCHECK=`ps -ef | grep fpm | grep -v grep`
  local APACHECHECK=`ps -ef | egrep 'apache|httpd|apache2' | grep -v egrep | grep -v grep`

  if [ ${#FPMCHECK} -eq 0 ]; then
    if [ ${#APACHECHECK} -gt 0 ]; then
      echo "php_flag engine off" > $DESTDIR/wp-content/uploads/.htaccess
      echo "==$INSTANCEID==Wrote htaccess file to uploads (mod_php style)" | tee -a $LOGFILE
      echo -e "\n\nRewriteEngine On\nRewriteBase /\nRewriteCond %{REQUEST_FILENAME} !-f\nRewriteCond %{REQUEST_FILENAME} !-d\nRewriteRule . /index.php [L]\n\n" > $DESTDIR/.htaccess
      echo "==$INSTANCEID==Wrote standard WP htaccess to $DESTDIR/.htaccess" | tee -a $LOGFILE
    fi
  elif [ ${#FPMCHECK} -gt 0 ]; then
    if [ ${#APACHECHECK} -gt 0 ]; then
      echo "Options -ExecCGI" > $DESTDIR/wp-content/uploads/.htaccess
      echo "==$INSTANCEID==Wrote htaccess file to uploads (fpm style)" | tee -a $LOGFILE
      echo -e "\n\nRewriteEngine On\nRewriteBase /\nRewriteCond %{REQUEST_FILENAME} !-f\nRewriteCond %{REQUEST_FILENAME} !-d\nRewriteRule . /index.php [L]\n\n" > $DESTDIR/.htaccess
      echo "==$INSTANCEID==Wrote standard WP htaccess to $DESTDIR/.htaccess" | tee -a $LOGFILE
    fi
  else
    echo "==$INSTANCEID==Apache not detected, skipping htaccess" | tee -a $LOGFILE
  fi
  
  echo "==$INSTANCEID==Install Complete." | tee -a $LOGFILE

} # END INSTALL
