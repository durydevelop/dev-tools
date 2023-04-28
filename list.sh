#! /bin/bash

while read line; do
    echo $line
	find -name "*.*" | grep "dd"
done < $1
#echo $line