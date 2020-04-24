#######################
# THE SEARCH FUNCTION #
#######################

search() {

  SEARCHDIR="$1"
  SEARCHDIR=${SEARCHDIR:-/}
  [ -d $SEARCHDIR ] || SEARCHDIR="/"

  local DATETIME=`date +%Y%m%d.%H%M`

  echo "==WPM FIND CALLED ON $DATETIME WITH VERSION $WPVERSION==" | tee -a $LOGFILE
  echo "==UNIQUE IDENTIFIER $INSTANCEID==" | tee -a $LOGFILE
  echo "==$INSTANCEID==Executing find on $SEARCHDIR" | tee -a $LOGFILE

  for WPCONFIG in `find $SEARCHDIR -type f -iname "wp-config.php" -exec dirname '{}' \; | xargs -0 -I {} echo {}`; do
  	DIRECTORY=`echo $WPCONFIG | tr -cd "[:print:]"`
  	if [ -d "$DIRECTORY/wp-content" ]; then
  		echo $DIRECTORY | tee -a $TEMPDIR/wordpress_installs.list
  	else
  		echo $DIRECTORY >> $TEMPDIR/orphans.list
  	fi
  done

  if [ -s $TEMPDIR/orphans.list ]; then
    echo "==$INSTANCEID==Orphaned WordPress installs found:" | tee -a $LOGFILE
  	cat $TEMPDIR/orphans.list | sed "s/^/==$INSTANCEID==" | tee -a $LOGFILE
  	echo "==$INSTANCEID==Orphans are in $TEMPDIR/orphans.list" | tee -a $LOGFILE
  else
  	echo "==$INSTANCEID==No orphaned WordPress installs found." | tee -a $LOGFILE
  fi
  
  echo "==$INSTANCEID==Results are in $TEMPDIR/wordpress_installs.list" | tee -a $LOGFILE
  echo "==$INSTANCEID==Search is complete." | tee -a $LOGFILE

} # END SEARCH
