#!/bin/bash

printhelp () {
	echo "
USAGE: branch-restore.sh [OPTION]
Print a list of git commit hashes to standard output.
Only those commits are considered that:
- do not have children,
- do not have a branch head pointing to them.

branch-restore creates a 'branch-restore' directory for temporary files.
It will not run if such a directory already exists.

branch-restore has to be run from the main directory of the git repository.
Either add it to the PATH or provide a relative path to branch-restore.sh file.

	-a, --all	prints the list of all commits without children
	-h, --help	prints this help message

EXAMPLES:
	Print all the details of commits to be restored:
./branch-restore.sh | xargs -n1 git cat-file -p
	Select a commit with fzf (preview shows its details) and switch to that commit:
./branch-restore.sh | fzf --preview='git cat-file -p {}' | xargs git checkout
	Select a commit with fzf, preview shows if there is a branch pointing at it or not:
./branch-restore.sh -a | fzf --preview='grep -rl {} .git/refs/heads/ | xargs basename 2>/dev/null || echo no branch'"
}

if [[ $# -gt 1 ]]; then
	echo "Wrong number of arguments" >&2
	printhelp >&2
	exit 1
fi

ALL=0
if [[ "$1" = "-a" ]] || [[ "$1" = "--all" ]]; then
	ALL=1
elif [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]; then
	printhelp
	exit 0
elif [[ $# -eq 1 ]]; then
	echo "Invalid argument" >&2
	printhelp >&2
	exit 1
fi

if [[ ! -d ".git" ]]; then
	echo "Not a git repository" >&2
	printhelp >&2
	exit 1
fi

OBJECTFILES=(.git/objects/??/*)
if [[ ${#OBJECTFILES[@]} -eq 0 ]]; then
	echo "No objects in this git repository" >&2
	exit 0
fi

mkdir branch-restore
if [[ $? -eq 1 ]]; then
	exit 1
fi

for FILE in ${OBJECTFILES[@]};
do
	FIRSTPART=$(basename $(dirname $FILE))
	SECONDPART=$(basename $FILE)
	OBJECT=$FIRSTPART$SECONDPART

	TYPE=$(git cat-file -t $OBJECT)
	if [[ $TYPE != "commit" ]]; then
		continue;
	fi

	echo $OBJECT >> branch-restore/commits
	git cat-file -p $OBJECT | grep -Po "(?<=parent )[0-9a-z]*" >> branch-restore/parents
done

sort branch-restore/commits > branch-restore/commitssorted

printall () {
	sort -u branch-restore/parents | diff branch-restore/commitssorted - | grep -Po "(?<=\< )[0-9a-z]*"
}

if [[ $ALL -eq 1 ]]; then
	printall
else
	printall > branch-restore/childless
	cat .git/refs/heads/* | sort -u | diff branch-restore/childless - | grep -Po "(?<=\< )[0-9a-z]*"
fi

rm -r branch-restore
