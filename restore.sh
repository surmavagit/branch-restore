#!/bin/bash

mkdir restore-branch
if [[ $? -eq 1 ]]; then
	echo 'a directory called "restore-branch" already exists'
	exit 1
fi

OBJECTFILES=(./.git/objects/??/*)
for FILE in ${OBJECTFILES[@]};
do
	FIRSTPART=$(basename $(dirname $FILE))
	SECONDPART=$(basename $FILE)
	OBJECT=$FIRSTPART$SECONDPART

	TYPE=$(git cat-file -t $OBJECT)
	if [[ $TYPE != "commit" ]]; then
		continue;
	fi

	echo $OBJECT >> restore-branch/commits
	git cat-file -p $OBJECT | grep -Po "(?<=parent )[0-9a-z]*" >> restore-branch/parents
done

sort restore-branch/commits > restore-branch/commitssorted
sort -u restore-branch/parents | diff restore-branch/commitssorted - | grep -Po "(?<=\< )[0-9a-z]*"

rm -r restore-branch
