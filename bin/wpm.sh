#!/bin/bash
. 6b4178521b3f/etc/wpm/wpm.conf
. 6b4178521b3f/lib/wpm-backup.sh
. 6b4178521b3f/lib/wpm-copy.sh
. 6b4178521b3f/lib/wpm-delete.sh
. 6b4178521b3f/lib/wpm-find.sh
. 6b4178521b3f/lib/wpm-install.sh
. 6b4178521b3f/lib/wpm-mangle.sh
. 6b4178521b3f/lib/wpm-password.sh
. 6b4178521b3f/lib/wpm-permissions.sh
. 6b4178521b3f/lib/wpm-rename.sh
. 6b4178521b3f/lib/wpm-settings.sh
. 6b4178521b3f/lib/wpm-update.sh
. 6b4178521b3f/lib/wpm-verify.sh

############################
# TRY BLOCK IMPLEMENTATION #
# SCRIPT HALTS ON FAILURE  #
############################

scream() { echo "$0: $*" >&2 | tee -a $LOGFILE; }
die() { scream "$*"; exit 1; }
try() { "$@" || die "cannot $*"; }

#############################
# MAKE SURE LOG FILE EXISTS #
#############################

([ -e $LOGFILE ] || try touch $LOGFILE ) && try chmod 660 $LOGFILE

#################################
# MAKE SURE THAT TEMPDIR EXISTS #
#################################

[ -d $TEMPDIR ] || try mkdir -m 770 -p $TEMPDIR;
[ -d $TEMPDIR ] || echo "$TEMPDIR does not exist"
[ -d $TEMPDIR ] || exit 1

########################################
# MAKE SURE THAT THE BACKUPPATH EXISTS #
########################################

if [ "$BACKUPPATH" != "PARENTOFGIVEN" ]; then
  [ -d $BACKUPPATH ] || try mkdir -m 770 -p $BACKUPPATH
  [ -d $BACKUPPATH ] || echo "$BACKUPPATH does not exist"
  [ -d $BACKUPPATH ] || exit 1
fi

####################################
# SET THE REFERENCE ID FOR LOGGING #
####################################

INSTANCEID=`openssl rand -hex 5`

###########################################
# IF USER VARIABLES ARE NOT SET IN CONFIG #
###########################################

if [ -z $SELECTED_GROUP ]; then
  NGINX=`ps -ef | grep nginx | grep -v root | grep -v grep | awk '{print $1}' | sort | uniq`
  HTTPD=`ps -ef | grep httpd | grep -v root | grep -v grep | grep -v tomcat | awk '{print $1}' | sort | uniq`
  APACHE=`ps -ef | grep apache | grep -v root | grep -v grep | grep -v tomcat | awk '{print $1}' | sort | uniq`
  [[ -z $NGINX ]] || SELECTED_GROUP=`id -g $NGINX`
  [[ -z $HTTPD ]] || SELECTED_GROUP=`id -g $HTTPD`
  [[ -z $APACHE ]] || SELECTED_GROUP=`id -g $APACHE`
  [ -z $SELECTED_GROUP ] && echo "no selected group found, please set it in  6b4178521b3f/etc/wpm/wpm.conf"
fi

######################
# THE USAGE FUNCTION #
######################

function usage() {
	printf "wpm version ${WPMVERSION}\n\n"

	case "$1" in
    -r|--rename)
    	printf "  -r | --rename \n"
  	  printf "\t %-21s \t %s \n" "-o | --oldname" "old domain name to be abandoned"
  	  printf "\t %-21s \t %s \n" "-n | --newname" "new domain name to be in use"
  	  printf "\t %-21s \t %s \n\n" "-p | --path" "location of installation"

  	  echo "This function will change the domain name of WordPress installation."
  	  echo "If you provide no path, it will default to your current directory."
  	  echo "Example: wpm -r -o foo.com -n bar.com -p /var/www/example"
  	  echo "Example: wpm -r -o foo.com -n bar.com"
    ;;

    -c|--copy)
    	printf "  -c | --copy \n"
    	printf "\t %-21s \t %s \n" "-o | --oldname" "original domain name"
	    printf "\t %-21s \t %s \n" "-n | --newname" "new domain name"
	    printf "\t %-21s \t %s \n" "-s | --source" "location of original installation"
	    printf "\t %-21s \t %s \n\n" "-d | --destination" "location for copy"

	    echo "This will duplicate a WordPress installation and assign it a provided domain name."
	    echo "Example: wpm -c -o foo.com -n bar.com -s /var/www/foo -d /var/www/bar"
    ;;

    -i|--install)
    	printf "  -i | --install \n"
	    printf "\t %-21s \t %s \n" "-d | --domain" "domain name to be used"
	    printf "\t %-21s \t %s \n" "-s | --skip-ftp" "skip ftpsockets config and permissions"
	    printf "\t %-21s \t %s \n\n" "-p | --path" "location for installation"

	    echo "This will install WordPress at the desired location."
	    echo "If no path is provided it will default to current directory."
      echo "Example: wpm -i -d foo.com -p /var/www/foo"
      echo "Example: wpm -i -d foo.com"
    ;;

    -u|--update)
    	printf "  -u | --update \n"
	    printf "\t %-21s \t %s \n" "-b | --backup" "do a backup first"
	    printf "\t %-21s \t %s \n" "-g | --plugins" "update plugins too"
	    printf "\t %-21s \t %s \n" "-s | --skip-ftp" "skip ftpsockets permissions"
	    printf "\t %-21s \t %s \n\n" "-p | --path" "location of the WP install"

      echo "This just runs an update to current on WordPress."
      echo "If no path is given, it will try the current directory."
      echo "Example: wpm -u -p /var/www/foo"
    ;;

    -p|--permissions)
    	printf "  -p | --permissions \n\n"

    	echo "This will attempt to set \"sane\" permissions on a WordPress installation."
    	echo "It will make a backup of permissions if getfacl is installed."
    	echo "If no path is provided, it will attempt to use the current directory."
    	echo "Example: wpm -p /var/www/foo"
    ;;

    -d|--delete)
      printf "  -d | --delete \n"
	    printf "\t %-21s \t %s \n" "-b | --backup" "do a backup first"
	    printf "\t %-21s \t %s \n\n" "-p | --path" "installation to be deleted"

	    echo "This will delete a WordPress installation, and optionally back it up first."
	    echo "Example: wpm -d -p /var/www/foo"
    ;;

    -b|--backup)
    	printf "  -b | --backup\t backup a wordpress installation \n"
	    printf "\t %-21s \t %s \n" "-n | --no-compress" "the xz or gz container won't actually be compressed"
	    printf "\t %-21s \t %s \n" "-d | --delete-old" "delete older backups"
	    printf "\t %-21s \t %s \n" "-s | --skip-uploads" "skip the uploads directory"
	    printf "\t %-21s \t %s \n\n" "-p | --path" "the WordPress install's location"

      echo "This will create a compressed tarball of the installation, including DB"
      echo "If no path is provided, it will default to the current directory."
      echo "Example: wpm -b -p /var/www/foo -n -d -s"
      echo "Example: wpm -b"
    ;;

    -w|--password)
    	printf "  -w | --password \n"
    	printf "\t %-21s \t %s \n" "-d | --duration" "duration of password change"
	    printf "\t %-21s \t %s \n" "-u | --username" "user who's password should be changed"
	    printf "\t %-21s \t %s \n" "-v | --view" "view available WP usernames"
	    printf "\t %-21s \t %s \n\n" "-p | --path" "location of the WP install"

	    echo "This will change the current password of a user."
	    echo "A duration of 0 can be used for permanent changed, and the default is 10 minutes."
	    echo "If no path is provided, it will attempt to use the current directory."
	    echo "Example: wpm -w -u admin -p /var/www/foo"
    ;;
    -e|--settings)
    	printf "  --settings \n\n"

    	echo "This allows you to view or change wpm settings."
	    echo "Example: wpm --settings list"
	    echo "Example: wpm --settings BACKUPPATH=\"PARENTOFGIVEN\""
	    echo "Example: wpm --settings LOGFILE=\"/home/admin/wpm.log\" BACKUPPATH=\"/home/admin/wpm_backups\""
    ;;

    -s|--search)
    	printf "  -s | --search \n\n"

    	echo "This will attempt to find WordPress installations."
    	echo "If no search path is provided, it will use /"
	    echo "Example: wpm --search /var/www"
    ;;

    -m|--mangle)
    	printf "  -m | --mangle \n"
	    printf "\t %-21s \t %s \n" "-n | --no-backup" "do not backup the WP installs first (bad idea, btw)"
	    printf "\t %-21s \t %s \n" "-p | --path" "the search path for installs"
	    printf "\t %-21s \t %s \n\n" "-s | --skip-search" "skip doing the search for installs"

	    echo "This will attempt to find WordPress installations and then update them."
	    echo "If you have recently run wpm -s you can skip rerunning it here with -s."
	    echo "If no search path is provided, it will use /"
	    echo "Example: wpm -m -p /var/www"
    ;;

    -v|--verify)
    	printf "  -v | --verify \n"
	    printf "\t %-21s \t %s \n" "-s | --scan" "scan with maldet"
	    printf "\t %-21s \t %s \n" "-m | --md5" "md5 presnet files against those from wordpress.org"
	    printf "\t %-21s \t %s \n" "-b | --backup" "run a backup first"
	    printf "\t %-21s \t %s \n" "-r | --replace" "replace modified files (requires --md5)"
	    printf "\t %-21s \t %s \n\n" "-p | --path" "location of the WP install"

      echo "This will attempt to detect and optionally remove malware, and/or replace files that are corrupt."
      echo "If no path is given it will attempt to use the current directory."
      echo "If you do not choose md5 or scan, it does nothing."
      echo "Example: wpm -v -m -s -b -r -p /var/www/foo"
    ;;

    -h|--help)
      printf "\n\n%b%s%b\n\n" "$RED" "Please tell me that you do not actually need help for help..." "$DEFAULT"
    ;;
  esac

  if [ -z $1 ]; then
    printf "%b%s \t %b%s%b\n" "$RED" "-r" "$CIAN" "rename a wordpress installation" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-c" "$CIAN" "copy a wordpress installation" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-i" "$CIAN" "install wordpress" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-u" "$CIAN" "update a wordpress installation" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-p" "$CIAN" "attempt to set sane permissions on a WP installation" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-d" "$CIAN" "delete a wordpress installation" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-b" "$CIAN" "backup a wordpress installation" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-w" "$CIAN" "change a wordpress user's password" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-e" "$CIAN" "change wpm settings" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-s" "$CIAN" "search for wordpress installations" "$DEFAULT"
    printf "%b%s \t %b%s%b\n" "$RED" "-m" "$CIAN" "find and update wordpress installations" "$DEFAULT"
    printf "%b%s \t %b%s%b\n\n" "$RED" "-v" "$CIAN" "verify a wordpress installation" "$DEFAULT"
  fi

} # END USAGE


#################
# LET'S DO THIS #
#################

case "$1" in
  -r|--rename) rename "${@:2}" ;;
  -c|--copy) copy "${@:2}" ;;
  -i|--install) install "${@:2}" ;;
  -u|--update) update "${@:2}" ;;
  -p|--permissions) permissions "${@:2}" ;;
  -d|--delete) delete "${@:2}" ;;
  -b|--backup) backup "${@:2}" ;;
  -w|--password) password "${@:2}" ;;
  -e|--settings) settings "${@:2}" ;;
  -s|--search) search "${@:2}" ;;
  -m|--mangle) mangle "${@:2}" ;;
  -v|--verify) verify "${@:2}" ;;
  -h|--help) usage "${@:2}" ;;
  *)
    if [ "$1" == "" ]; then
      usage
    else
      echo "$1 not implemented"
      exit 1
    fi
  ;;
esac

# EOF
