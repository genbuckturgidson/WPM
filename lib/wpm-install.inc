########################
# THE INSTALL FUNCTION #
########################

function install() {

	POSIT=()
	while [[ $# -gt 0 ]]
	do
		key="$1"
  	case $key in
    	-d|--domain) name="$2"; shift;;
    	-p|--path) target="$2"; shift;;
    	*) echo "$1 not implemented" ; POSIT+=("$1") ;;
    esac
    shift
  done
  set -- "${POSIT[@]}"

	target="${target:-`pwd`}"

  local dt=`date +%Y%m%d.%H%M`

  [ -z $name ] && echo "you must providea domain name"
  [ -z $name ] && exit 1

  [ -f "$target/wp-config.php" ] && echo "this is already a wordpress installation"
  [ -f "$target/wp-config.php" ] && exit 1

  [ -d "$target/wp-content" ] && echo "this is already a wordpress installation"
  [ -d "$target/wp-content" ] && exit 1

  echo "==WP INSTALL CALLED ON $dt WITH VERSION $WPVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=starting install in `pwd`==" >> $LOGFILE

  if [ "$target" == "`pwd`" ]; then
  	echo "Using `pwd` as the install path"
  else
  	cd $target
  fi

  local p=`openssl rand -hex 5`
  local t=`echo $name | sed -e 's/\.//g' | tr '-' '_'| cut -c -10`
  local d=$t
  d+=`openssl rand -hex 2`

  echo "The password and name seed have been generated"
  echo "=$r=Password: $p Seed: $t have been generated" >> $LOGFILE
  echo "=$r=starting install in `pwd`==" >> $LOGFILE

  echo "getting recent wordpress version"

  echo "=$r=Checking $TEMPDIR/wp-installer" >> $LOGFILE
  [ -d $TEMPDIR/wp-installer ] || try mkdir -p $TEMPDIR/wp-installer

  echo "=$r=Removing old versions" >> $LOGFILE
  try find $TEMPDIR/wp-installer/ -mtime +1 -name wordpress.latest.tar -exec rm -fv '{}' \;

  if [ -e $TEMPDIR/wp-installer/wordpress.latest.tar ]; then
    echo "=$r=Recent version already present" >> $LOGFILE
  else
    try wget -O $TEMPDIR/wp-installer/wordpress.latest.tar.gz https://wordpress.org/latest.tar.gz --no-check-certificate &> /dev/null
    try touch $TEMPDIR/wp-installer/wordpress.latest.tar
    try gunzip $TEMPDIR/wp-installer/wordpress.latest.tar.gz &> /dev/null
    echo "=$r=Recent version downloaded" >> $LOGFILE
  fi

  if [ ! -e $TEMPDIR/wp-installer/wordpress.latest.tar ]; then
    echo "=$r=Cannot get archive at $TEMPDIR/wp-installer/" >> $LOGFILE
    echo "can't get archive at $TEMPDIR/wp-installer/" && exit 1
  fi

  echo ="$r"=Extracting Wordpress in `pwd` >> $LOGFILE

  if tar -f $TEMPDIR/wp-installer/wordpress.latest.tar -x --strip-components=1; then
    echo "=$r=Extracting Wordpress in `pwd` complete" >> $LOGFILE
  else
    echo "=$r=Extracting Wordpress in `pwd` failed, trying with legacy tar options" >> $LOGFILE
    if tar -f $TEMPDIR/wp-installer/wordpress.latest.tar -x --strip-path=1; then
      echo "=$r=Extracting Wordpress in `pwd` complete" >> $LOGFILE
    else
      echo "=$r=Extracting Wordpress completely failed in `pwd`" >> $LOGFILE
      exit 1
    fi
  fi

  echo Writing config file
  echo "=$r=Generating configuration" >> $LOGFILE

  echo -e "<?php\ndefine('DB_NAME', 'database_name_here');\ndefine('DB_USER', 'username_here');\ndefine('DB_PASSWORD', 'password_here');\ndefine('DB_HOST', 'localhost');\ndefine('DB_CHARSET', 'utf8');\ndefine('DB_COLLATE', '');\n"| sed -e "s/database_name_here/""$d""/g" | sed -e "s/username_here/""$d""/g" | sed -e "s/password_here/""$p""/g" > wp-config.php

  try wget -O - -q https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php

  echo "creating FTP user"
  echo "=$r=Adding ftp user $t==" >> $LOGFILE

  [ -z $SELECTED_USER ] && uid="9001" || uid=`id -n $SELECTED_USER`

  # THE UIDS WE KNOW WE SHOULDNT BE USING
  local badness=("0" "2" "3" "4" "5" "6" "7" "8" "9" "10" "13" "34" "38" "39" "41" "65534" "100")
  for baddy in ${badness[*]}
  do
    if [ $uid -eq $baddy ]; then
      echo "UID of $baddy is not allowed setting to over nine thousand"
      uid="9001"
    fi
  done # END BADNESS CHECK

  try useradd $t -u $uid -g $SELECTED_GROUP -d $target -s /bin/sh -p $(openssl passwd -1 $p) -o
  echo "=$r=FTP user added" >> $LOGFILE

  echo "define('FS_METHOD', 'ftpsockets');" >> wp-config.php
  echo "define('FTP_USER', '$t');" >> wp-config.php
  echo "define('FTP_PASS', '$p');" >> wp-config.php
  echo "define('FTP_HOST', '127.0.0.1');" >> wp-config.php
  echo "=$r=FTP details and FS_METHOD added to config" >> $LOGFILE
  echo "FTP user and FS_METHOD setup complete"

  echo -e "\$table_prefix = 'wp_';\n\ndefine ('WPLANG', '');\ndefine('WP_DEBUG', false);\nif ( ! defined('ABSPATH') )\ndefine('ABSPATH', dirname(__FILE__) . '/');\nrequire_once(ABSPATH . 'wp-settings.php');" >> wp-config.php

  local de=`mysql -e "show databases like '$d'" | wc -l`
  if [ "$de" -lt 1 ]; then
    echo Creating database "$d"
    echo "=$r=Creating database $d" >> $LOGFILE
    echo "create database $d" | mysql
    echo granting database permissions
    echo "=$r=Granting permissions on $d to $d@localhost" >> $LOGFILE
    echo "grant all on $d.* to '$d'@'localhost' identified by '$p'" | mysql
  else
    echo error database already exists
    echo "=$r=Database $d already exists" >> $LOGFILE
    exit 1
  fi

  local de=`mysql -e "show databases like '$d'" | wc -l`
  if [ "$de" -lt 1 ]; then
    echo "Database creation failed, refusing to continue"
    echo "=$r=Database creation failed. Terminating." >> $LOGFILE
    exit 1
  fi

  echo ="$r=Setting Permissions on $2" >> $LOGFILE
  echo "setting permissions"

  try mkdir $target/wp-content/uploads
  g="`getent group $SELECTED_GROUP | cut -d ':' -f 1`"
  printf "USER: $t\t GROUP: $g\n"
  try chown -R $t:$g $target
  try find $target -type d -exec chmod 750 '{}' \;
  try find $target -type f -exec chmod 640 '{}' \;

  [ -d $target/wp-content/uploads ] && try chmod 770 $target/wp-content/uploads || try install -d -m 0770 $target/wp-content/uploads

  local fpmcheck=`ps -ef | grep fpm | grep -v grep`
  local apachecheck=`ps -ef | egrep 'apache|httpd|apache2' | grep -v egrep | grep -v grep`

  if [ ${#fpmcheck} -eq 0 ]; then
    if [ ${#apachecheck} -gt 0 ]; then
      echo "php_flag engine off" > $target/wp-content/uploads/.htaccess
      echo "=$r=Wrote htaccess file to uploads (mod_php style)" >> $LOGFILE
      echo -e "\n\nRewriteEngine On\nRewriteBase /\nRewriteCond %{REQUEST_FILENAME} !-f\nRewriteCond %{REQUEST_FILENAME} !-d\nRewriteRule . /index.php [L]\n\n" > $target/.htaccess
      echo "=$r=Wrote standard WP htaccess to $target/.htaccess" >> $LOGFILE
    fi
  elif [ ${#fpmcheck} -gt 0 ]; then
    if [ ${#apachecheck} -gt 0 ]; then
      echo "Options -ExecCGI" > $target/wp-content/uploads/.htaccess
      echo "=$r=Wrote htaccess file to uploads (fpm style)" >> $LOGFILE
      echo -e "\n\nRewriteEngine On\nRewriteBase /\nRewriteCond %{REQUEST_FILENAME} !-f\nRewriteCond %{REQUEST_FILENAME} !-d\nRewriteRule . /index.php [L]\n\n" > $target/.htaccess
      echo "=$r=Wrote standard WP htaccess to $target/.htaccess" >> $LOGFILE
    fi
  else
    echo "Apache isn't running, skipping htaccess"
    echo "=$r=Apache not detected, skipping htaccess" >> $LOGFILE
  fi

  echo "Installation of WordPress is complete."
  echo "=$r=Install Complete." >> $LOGFILE

  unset d
  unset de
  unset t
  unset p
  unset n
  unset uid
  unset dt
  unset g
  unset badness
  unset baddy
  unset fpmcheck
  unset apachecheck
  unset target
  unset name

} # END INSTALL
