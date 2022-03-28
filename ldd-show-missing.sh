#!/bin/bash

if [ -z "$1" ]; then
	echo "Missing filename"
	echo "Usage: $(basename $0) filename [output filename]"
	exit
fi
readarray -t array <<< $(ldd $1 | grep "not found")

for (( n=0; n < ${#array[*]}; n++)); do
	var=${array[n]%" => "*}
	var="${var#"${var%%[![:space:]]*}"}"
	echo -e "\e[33mMissing $var\e[0m"
	if [ -z "$2" ]; then
		echo "$var" >> $2
	fi
done
