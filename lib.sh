#!/bin/bash

# Foreground colors
BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

# Background colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_MAGENTA='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# Modify colors
BOLD='\033[1m'
UNDERLINE='\033[4m'
INVERSE='\033[7m'
NC='\033[0m'

# Print color helpers
echo_info()  { echo -e "${BOLD}${GREEN}$1${NC}"; }
echo_ask()   { echo -e "${BOLD}${WHITE}$1${NC}"; }
echo_warn()  { echo -e "${BOLD}${YELLOW}$1${NC}"; }
echo_error() { echo -e "${BOLD}${WHITE}${BG_RED}$1${NC}"; }

# Write text line in a file: if does not exist, add it
# $1    ->  filename
# $2    ->  string to add as line
function write_line_in_file_if_not_exists() {
    if [[ -f $1 ]]; then
        ret=$(grep -xF "$2" $1 || echo "$2" >> $1)
    else
        echo -e "\e[31m $1 NOT FOUND\e[0m"
    fi
}

# Clone a git repo using $1 as dest folder and $2 as git url
function git_clone_if_not_exists() {
    echo -n -e "Check for \e[33m$1\e[0m repo "
    if [[ ! -d "$1/.git" ]]; then
        echo ""
        echo -e "\e[33mCloning $2\e[0m"
        git clone $2 $1
        ret=$?
        if [[ $ret -eq 0 ]]; then
            echo -e "Cloned \e[32mOK\e[0m"
        else
            echo -e "\e[1;41mERROR $ret\e[0m"
            error_msg="Cloning $2 failed.\nMay be you don't have a ssh public key, try to generate it with command 'ssh-keygen -t rsa -b4096 -C \"your@mail.it\"' or try to use -https option".
        fi
    else
        echo -e "\e[32mOK\e[0m"
    fi
}

# Create $1 folder if does not exists
function dir_create_if_not_exists() {
    echo -n -e "Checking for \e[33m$1\e[0m folder "
    if [[ ! -d "$1" ]]; then
        mkdir -p $1
        if [[ ! -d "$1" ]]; then
            echo -e "\e[31mCan not create...stopping\e[0m"
            exit
        fi
        echo -e "\e[32mCREATED\e[0m"
    else
        echo -e "\e[32mOK\e[0m"
    fi
}

# Add a permanent share to fstab
# $1    ->  Windows share       //vsgiove/prodig
# $2    ->  Local path          /mnt/vsgiove/prodig
# $3    ->  Username
# $4    ->  Password
# $5    ->  Domain
function add_share_if_not_exists() {
    if [[ -f /etc/fstab ]]; then
        ENTRY="$1 $2 cifs username=$3,password=$4,domain=$5,file_mode=0666,dir_mode=0777,uid=1000,gid=1000 0 0"
        ret=$(grep -xF "$ENTRY" /etc/fstab || echo $ENTRY >> /etc/fstab)
        #grep -xF "$1" /etc/fstab
        if [[ $ret == "" ]]; then
            if [[ $SHARE_ADDED != true ]]; then
                echo
            fi
            echo -e "$1 \e[32maggiunta\e[0m"
            SHARE_ADDED=true
        fi
        SHARE_DONE=true
    else
        echo -e "etc/fstab \e[33mnon trovato\e[0m"
        SHARE_DONE=false
    fi
}

# Mount a cifs share
# $1    ->  Windows share       //vsgiove/prodig
# $2    ->  Local path          /mnt/vsgiove/prodig
# $3    ->  Username
# $4    ->  Password
# $5    ->  Domain
function mount_share() {
	if [[ ! -d $2 ]]; then
        echo -e "\e[33mCreo  $2\e[0m"
        mkdir  -p $2
    fi

    if [[ $(findmnt -M "$2") ]]; then
        echo -e "\e[33m$2 già montata, la smonto...\e[0m"
        RET=$(umount $2)
        if [[ $RET == "" ]];then
            echo "...fatto"
        fi
    fi

    if [[ $3 != "" ]]; then
        OPTIONS="-o user=$3,pass=$4,dom=$5,nounix,noserverino"
    fi
        echo -e "\e[33mMonto:\e[0m"
        RET=$(mount -t cifs $OPTIONS $1 $2)
    if [[ $RET == "" ]];then
        echo "...fatto"
    fi
}

# Test if a cifs share works
# $1    ->  Windows share       //vsgiove/prodig
# $2    ->  Username
# $3    ->  Password
# $4    ->  Domain
# &?	-> 0 on success otherwise 1
function test_share() {
	TMP_SHARE="/tmp/share_test"
	local FUNC_RET=0
	if [[ ! -d $2 ]]; then
        echo -e "\e[33mCreo  $TMP_SHARE \e[0m"
        mkdir -p $TMP_SHARE
    fi

    if [[ $(findmnt -M $TMP_SHARE) ]]; then
        echo -e "\e[33m$TMP_SHARE già montata, la smonto...\e[0m"
        RET=$(umount $TMP_SHARE)
        if [[ $RET == "" ]];then
            echo "...fatto"
        fi
    fi

    if [[ $3 != "" ]]; then
        OPTIONS="-o user=$2,pass=$3,dom=$4,nounix,noserverino"
    fi
        echo -e "\e[33mMonto con: mount -t cifs $OPTIONS $1 $TMP_SHARE\e[0m"
        RET=$(mount -t cifs $OPTIONS $1 $TMP_SHARE)
    if [[ $(findmnt -M $TMP_SHARE) ]]; then
        echo -e "\e[33mTest riuscito, smonto ed elimino...\e[0m"
        RET=$(umount $TMP_SHARE)
        if [[ $RET == "" ]];then
            echo "...fatto"
        fi
    else
        echo -e "\e[31mTest NON riuscito\e[0m"
	FUNC_RET=1
    fi
    
    rmdir $TMP_SHARE
    return $FUNC_RET
}

# Install pkg if does not exists
# $1	->  pkg name (e.g. smb)
# [$2]	->  command used to check pkg (e.g. smbpasswd)
# return 1 on success otherwise 0
# How to check return value:
#if [[ $() == 0 ]]; then
#	echo ""
#	echo -e -n "\e[1;41m$1 install failed\e[0m"
#fi
function install_if_not_exists() {
	local PKG="$1"
    	local CMD="${2:-}"
	local MISSING=0
	if [[ -z "$CMD" ]]; then
		# 2nd argument not found use dpkg
		# search for "$PKG " or "$PKG:" (for lib like libboost-dev:amd64)
		#RET=$(dpkg -l | grep "$1 \|$1:")
		RET=$(dpkg -s "$PKG")
		#echo "RET=$RET"
		if [[ -z $RET ]];then
		# pkg not found
		MISSING=1
	    fi
	else
	    if ! command -v "$CMD" &> /dev/null; then
		# command not found
		MISSING=1
	    fi
	fi
	
	if [[ $MISSING == 1 ]]; then
		echo ""
		echo -e -n "\e[33m$1 is not installed, install it? \e[0m"
		read -p "(Y/n) " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Nn]$ ]]; then
			return 1
		fi
		sudo apt-get install -y $PKG;
		if [ $? -eq 0 ]; then
			echo -e "\e[32m$1 install done\e[0m"
		else
			return 0
		fi

		sudo apt-get install -y -f
		if [ ! $? -eq 0 ]; then
			echo -e "\e[1;41mMissed dependency install failed\e[0m"
			return 0
		fi
		return 1
	fi
}

# Replace pattern in file
# $1    ->  Source filename
# $2    ->  Source pattern
# $3    ->  Replace pattern
# [$4]  ->  Destination filename (if omitted, source file is updated)
function replace-in-file() {
	if [[ ! -f "$1" ]]; then
		echo -e "\e[1;41m$1 does not exist\e[0m"
		exit 1
	fi
	
	if [[ -z $4 ]]; then
		# 4th argument not found, update source file
		sed -i "s/$2/$3/g" $1
	else
		sed "s/$2/$3/g" $1 > $4
	fi
}

# removes duplicate strings in a list
function dedupe-list {
	local list delimiter retVal
	list=${1-}
	if [[ "${list}" == "" ]]; then
	return 1
	fi
	delimiter=${2-}
	if [[ "${delimiter}" == "" ]]; then
	delimiter=","
	fi

	echo "${list}" | tr "'${delimiter}'" '\n' | sort -u | xargs | tr ' ' ','
}
  
# Checks if a value is likely an IP address
function is-ip {
	local param pattern
	param="${1}"
	pattern="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
	if [[ "${param}" =~ $pattern ]]; then
	return 0
	fi
	return 1
}
