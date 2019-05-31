#######################
# THE SEARCH FUNCTION #
#######################

search() {

  [ -z $1 ] && path=`pwd` || path=$1

  local dt=`date +%Y%m%d.%H%M`

  echo "==WPM FIND CALLED ON $dt WITH VERSION $WPVERSION==" >> $LOGFILE
  echo "==UNIQUE IDENTIFIER $r==" >> $LOGFILE
  echo "=$r=Executing find on $path" >> $LOGFILE

  for i in `find $path -type f -iname "wp-config.php" -exec dirname '{}' | xargs -0 -I {} echo {}`; do
  	location=`echo $i | tr -cd "[:print:]"`
  	if [ -d "$location/wp-content" ]; then
  		echo $location | tee -a $TEMPDIR/wordpress_installs.list
  	else
  		echo $location >> $TEMPDIR/orphans.list
  	fi
  done

  echo "=$r=WordPress installations found are as follows:" >> $LOGFILE
  sed 's/^/=$r=/' $TEMPDIR/wordpress_installs.list >> $LOGFILE

  printf "\n Orphaned wp-config.php file directories are listed in $TEMPDIR/orphans.list \n\n"

  unset line
  unset path
  unset dt

} # END SEARCH
