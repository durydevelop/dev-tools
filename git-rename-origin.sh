#! /bin/bash

if [[ -z $1 ]]; then
	echo "usage: git-rename-origin <new url>"
	exit 1
fi

git remote rename origin old-origin
git remote add origin %1
git remote set-url origin $1
git push -u origin --all
git push -u origin --tags

echo New origin
git remote show origin
echo Old origin
git remote show old-origin
