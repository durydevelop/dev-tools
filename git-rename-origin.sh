#! /bin/bash

git remote rename origin old-origin
git remote add origin %1
git remote set-url origin git@gitlab.com:durydevelop/git-tools.git
git push -u origin --all
git push -u origin --tags

echo New origin
git remote show origin
echo Old origin
git remote show old-origin
