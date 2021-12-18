#!/bin/bash

POSIT=()
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-f|--file) FILE=$2; shift;;
		-n|--new) NEW=$2; shift;;
		-o|--old) OLD=$2; shift;;
		*) echo "$1 not implemented" ; POSIT+=("$1") ;;
	esac
	shift
done
set -- "${POSIT[@]}"

if [ -z $FILE ] || [ -z $NEW ] || [ -z $OLD ]; then
	echo "You must provide a file, a new domain, and an old domain"
	exit 1
fi

sed 's/;s:/;\ns:/g' $FILE | awk -F'"' '/s:.+'$OLD'/ {sub("'$OLD'", "'$NEW'"); n=length($2)-1; sub(/:[[:digit:]]+:/, ":" n ":")} 1' | sed ':a;N;$!ba;s/;\ns:/;s:/g' | sed "s/$OLD/$NEW/g" > ${FILE}.tmp

mv ${FILE}.tmp ${FILE}
