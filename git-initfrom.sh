#!/bin/sh
ShowUsage() {
	echo "Inizializza la cartella corrente per un repository git."
	echo "usage: git-initfrom.sh <git repository> [Nome Utente] [Email Utente]"
	echo
	echo "	<git repository>	URL del repository git"
	echo "	[Nome Utente]		Opzionale: nome identità, espressa come Nome Cognome."
	echo "	[Email Utente]		Opzionale: email identità."
}

if [[ $1 == "" ]] ; then
	ShowUsage
	exit 1
fi

if [[ $1 == "-h" ]] ; then
	ShowUsage
	exit 1
fi

if [[ $2 != "" ]] ; then
	echo user $2
	git config --global user.name $2
fi

if [[ $3 != "" ]] ; then
	git config --global user.email $3
fi

git init
git remote add origin $1
touch README.md
git add .
git commit -m "Initial Commit"
git push -u origin master
