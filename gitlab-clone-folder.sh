#!/bin/bash

function help {
  printf "$1
Clones a specific directory from the master branch of a git repository.

Syntax:
  $(basename $0) [--delrepo] repoUrl sourceDirectory [targetDirectory]

If targetDirectory is not specified it will be set to sourceDirectory.
Downloads a sourceDirectory from a Git repository into targetdirectory.
If targetDirectory is not specified, a directory named after `basename sourceDirectory`
will be created under the current directory.

If --delrepo is specified then the .git subdirectory in the clone will be removed after cloning.


Example 1:
Clone the tree/master/django/conf/app_template directory from the master branch of
git@github.com:django/django.git into ./app_template:

\$ $(basename $0) git@github.com:django/django.git django/conf/app_template

\$ ls app_template/django/conf/app_template/
__init__.py-tpl  admin.py-tpl  apps.py-tpl  migrations  models.py-tpl  tests.py-tpl  views.py-tpl


Example 2:
Clone the django/conf/app_template directory from the master branch of
https://github.com/django/django/tree/master/django/conf/app_template into ~/test:

\$ $(basename $0) git@github.com:django/django.git django/conf/app_template ~/test

\$ ls test/django/conf/app_template/
__init__.py-tpl  admin.py-tpl  apps.py-tpl  migrations  models.py-tpl  tests.py-tpl  views.py-tpl

"
  exit 1
}

if [ -z "$1" ]; then help "Error: repoUrl was not specified.\n"; fi
if [ -z "$2" ]; then help "Error: sourceDirectory was not specified."; fi

if [ "$1" == --delrepo ]; then
  DEL_REPO=true
  shift
fi

REPO_URL="$1"
SOURCE_DIRECTORY="$2"
if [ "$3" ]; then
  TARGET_DIRECTORY="$3"
else
  TARGET_DIRECTORY="$(basename $2)"
fi

echo "Cloning into $TARGET_DIRECTORY"
mkdir -p "$TARGET_DIRECTORY"
cd "$TARGET_DIRECTORY"
git init
git remote add origin -f "$REPO_URL"
git config core.sparseCheckout true

echo "$SOURCE_DIRECTORY" > .git/info/sparse-checkout
git pull --depth=1 origin main

if [ "$DEL_REPO" ]; then rm -rf .git; fi
