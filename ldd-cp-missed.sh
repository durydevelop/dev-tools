#!/bin/bash

readarray -t array <<< $(ldd $1 | grep $MINGW_PREFIX)

for (( n=0; n < ${#array[*]}; n++)); do
	echo "Missing ${array[n]}"
	missed=${array[n]##*" => "}
	missed=${missed%" (0x"*}
	echo -e "\e[33mCopy $missed\e[0m"
	cp $missed ./
done
