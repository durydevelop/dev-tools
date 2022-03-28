#! /bin/bash

while read line; do
    cp $1 $2
done < $3
