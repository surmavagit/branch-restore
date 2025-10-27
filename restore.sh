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
	branch-restore.sh | xargs -n1 git cat-file -p
	branch-restore.sh | fzf --preview='git cat-file -p {}' | xargs git checkout
	branch-restore.sh -a | fzf --preview='grep -rl {} .git/refs/heads/ | xargs basename 2>/dev/null || echo no branch'"
}

if [[ $# -gt 1 ]]; then
	echo "Wrong number of arguments" >&2
	printhelp >&2
	exit 1
fi

LEAVES=0
if [[ "$1" = "-a" ]] || [[ "$1" = "--all" ]]; then
	LEAVES=1
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

mkdir branch-restore
if [[ $? -eq 1 ]]; then
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

	echo $OBJECT >> branch-restore/commits
	git cat-file -p $OBJECT | grep -Po "(?<=parent )[0-9a-z]*" >> branch-restore/parents
done

sort branch-restore/commits > branch-restore/commitssorted

printleaves () {
	sort -u branch-restore/parents | diff branch-restore/commitssorted - | grep -Po "(?<=\< )[0-9a-z]*"
}

if [[ $LEAVES -eq 1 ]]; then
	printleaves
else
	printleaves > branch-restore/leaves
	cat ./.git/refs/heads/* | sort -u | diff branch-restore/leaves - | grep -Po "(?<=\< )[0-9a-z]*"
fi

rm -r branch-restore
