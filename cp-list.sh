#! /bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Missing parameters."
	echo "Usage: $(basename $0) filename sourcedir destdir"
	exit
fi

if [ -z "$3" ]; then
	from=$(pwd)
	to=$2
else
	from=$2
	to=$3
fi

while read line; do
    cp $2 $3
done < $1
