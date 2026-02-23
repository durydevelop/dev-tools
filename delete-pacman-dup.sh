#!/bin/bash 
##Remove packages from cache not installed
#and download any installed pkgs not cached

pacman -Sc 

pacman -Q | sed s/' '/-/g > /tmp/installed 


for pkg in `ls /var/cache/pacman/pkg` 
do 
        name=${pkg%%.pkg.tar.gz} 
        if [[ ! `grep $name /tmp/installed` ]] 
        then 
                echo Removing $name 
                rm -f /var/cache/pacman/pkg/$pkg 
        fi 
done 

pacman -Q | cut -d ' ' -f 1 > /tmp/installed 
pacman -Sl | cut -d ' ' -f 2 >> /tmp/installed 

pacman -Sw `sort /tmp/installed | uniq -d`