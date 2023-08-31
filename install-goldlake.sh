#! /bin/bash
# Create $1 folder if does not exists
function create_if_not_exists() {
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

# Clone a git repo using $1 as dest folder and $2 as git url
function clone_if_not_exists() {
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

# Install pkg if does not exists
# $1	->  pkg name (e.g. smb)
# [$2]	->  command used to check pkg (e.g. smbpasswd)
function install_if_not_exists() {
	local MISSING=0
	if [[ -z $2 ]]; then
		# 2nd argument not found use dpkg
		# search for "$1 " or "$1:" (for lib like libboost-dev:amd64)
		RET=$(dpkg -l | grep "$1 \|$1:")
		#echo "RET=$RET"
		if [[ $RET == "" ]];then
		# pkg not found
		MISSING=1
	    fi
	else
	    if ! command -v $2 &> /dev/null; then
		# command not found
		MISSING=1
	    fi
	fi
	
	if [[ $MISSING == 1 ]]; then	
		echo ""
		echo -e -n "\e[33m$1 is not installed, install it? \e[0m"
		read -p "(Y/n)" -n 1 -r
			echo
			if [[ $REPLY =~ ^[Nn]$ ]]; then
				return
			fi
		sudo apt-get install -y $1;
		if [ $? -eq 0 ]; then
			echo -e "\e[32m$1 install done\e[0m"
		else
			echo -e "\e[1;41m$1 install failed\e[0m"
		exit 1
		fi

		sudo apt-get install -y -f
		if [ ! $? -eq 0 ]; then
			echo -e "\e[1;41mMissed dependency install failed\e[0m"
		fi
	fi
}

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

#################################### entry-point ####################################
EMSDK_ROOT=$DDEV_ROOT/cpp/lib/emsdk

create_if_not_exists $DDEV_ROOT/cpp/src-mcu/rpi/goldlake
clone_if_not_exists $DDEV_ROOT/cpp/src-mcu/rpi/goldlake/goldlake-frontend git@gitlab.com:durydevelop/cpp/src-mcu/rpi/goldlake/goldlake-frontend.git

if [[ ! -d $EMSDK_ROOT ]]; then
	echo -n "emsdk is not installed, install it? "
	read -p "(Y/n)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		exit 1
	fi
	install_if_not_exists bzip2
	clone_if_not_exists $EMSDK_ROOT https://github.com/emscripten-core/emsdk.git
fi

echo -e "\e[33mUpdate and activate emsdk\e[0m"
EMSDK_QUIET=1
cd $EMSDK_ROOT
./emsdk install latest
./emsdk activate latest --permanent &> /dev/null
write_line_in_file_if_not_exists "$HOME/.profile" "EMSDK_QUIET=1 . $EMSDK_ROOT/emsdk_env.sh"
if [[ $(printenv EMSDK) == "" ]]; then
	echo -e "\e[38;5;9mYou need to restart your shell. Close and reopen it or type \"source ~/.profile\" command.\e[0m"
fi
