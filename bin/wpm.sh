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

[ -d $TEMPDIR ] || try mkdir -m 770 -p $TEMPDIR
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
	printf "wpm version ${WPMVERSION}\n"
	printf "usage:\n"

	printf "  -b | --backup\t backup a wordpress installation \n"
	printf "\t %-21s \t %s \n" "-n | --no-compress" "the xz or gz container won't actually be compressed"
	printf "\t %-21s \t %s \n" "-d | --delete-old" "delete older backups"
	printf "\t %-21s \t %s \n" "-s | --skip-uploads" "skip the uploads directory"
	printf "\t %-21s \t %s \n\n" "-p | --path" "the WordPress install's location"

	printf "  -c | --copy\t copy a WP install from one domain/directory to another \n"
	printf "\t -o | --oldname \n"
	printf "\t -n | --newname \n"
	printf "\t -s | --source \n"
	printf "\t -d | --destination \n\n"
	
	printf "  -d | --delete\t delete a WP install and DB \n"
	printf "\t -b | --backup\t do a backup first \n"
	printf "\t -p | --path \n\n"
	
	printf "  -s | --search\t locate all WP installs \n"
	printf "\t example: wpm --search /var/www/ \n\n"
	
	printf " -i | --install\t install wordpress \n"
	printf "\t -d | --domain \n"
	printf "\t -p | --path \n\n"
	
	printf " -m | --mangle\t find and then update all WordPress installs \n"
	printf "\t %-21s \t %s \n" "-n | --no-backup" "do not backup the WP installs first (bad idea, btw)"
	printf "\t %-21s \t %s \n" "-p | --path" "the search path for installs"
	printf "\t %-21s \t %s \n\n" "-s | --skip-search" "skip doing the search for installs"
	
	printf "  -w | --password\t change a user password permanently/temporarily \n"
	printf "\t %-21s \t %s \n" "-d | --duration" "duration of password change (0 for permanent, default 10 mins)"
	printf "\t %-21s \t %s \n" "-u | --username" "user who's password should be changed"
	printf "\t %-21s \t %s \n" "-v | --view" "view the WP usernames"
	printf "\t %-21s \t %s \n\n" "-p | --path" "location of the WP install"
	
	printf "  -p | --permissions\t reset file/directory perms to safe values \n"
	printf "\t example: wpm -p /var/www/html \n\n"
	
	printf "  -r | --rename\t change the domain name of WP install \n"
	printf "\t -o | --oldname \n"
	printf "\t -n | --newname \n"
	printf "\t -p | --path \n\n"

	printf "  --settings\t change or view settings \n"
	printf "\t example: wpm --settings list \n"
	printf "\t example: wpm --settings BACKUPPATH=/var/www/backup \n\n"
	
	printf "  -u | --update\t update a wordpress install \n"
	printf "\t %-21s \t %s \n" "-b | --backup" "do a backup first"
	printf "\t %-21s \t %s \n" "-g | --plugins" "update plugins too"
	printf "\t %-21s \t %s \n\n" "-p | --path" "location of the WP install"
	
	printf "  -v | --verify\t scan a wordpress install \n"
	printf "\t %-21s \t %s \n" "-s | --scan" "scan with maldet"
	printf "\t %-21s \t %s \n" "-m | --md5" "md5 presnet files against those from wordpress.org"
	printf "\t %-21s \t %s \n" "-b | --backup" "run a backup first"
	printf "\t %-21s \t %s \n" "-r | --replace" "replace modified files (requires --md5)"
	printf "\t %-21s \t %s \n\n" "-p | --path" "location of the WP install"

	printf "  -h | --help\t print this help text \n"
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
  --settings) settings "${@:2}" ;;
  -s|--search) search "${@:2}" ;;
  -m|--mangle) mangle "${@:2}" ;;
  -v|--verify) verify "${@:2}" ;;
  -h|--help) usage ;;
  --) break ;;
  *) echo "$1 not implemented" ; exit 1 ;;
esac

# EOF
