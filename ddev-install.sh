#! /bin/bash

# TODO: Check environments using array

Version=1.0.6
GITLAB_ACCESS_TOKEN="read-only:XRQgs6iGq8TQ6xvoDmDk"
ENV_DDEV_GSOAP_TEMPLATES="DDEV_GSOAP_TEMPLATES"
ENV_DDEV_ROOT_PATH="DDEV_ROOT"
ENV_DDEV_TOOLS_PATH="DDEV_TOOLS"
DEFAULT_DDEV_ROOT_PATH=$HOME/Dev

# How to use:
# ~$ mkdir Dev
# ~$ cd Dev
# ~$ git clone https://read-only:XRQgs6iGq8TQ6xvoDmDk@gitlab.com:durydevelop/dev-tools.git
# ~$ cd dev-tools
# ~$ ./ddev-install.sh

# Result structure:
# Dev\
#     |cpp\
#     |    |helpers_cmake\  <git@gitlab.com:durydevelop/cpp/helpers_cmake.git>
#     |    |
#     |    |lib\
#     |    |    	 |dpptools <git@gitlab.com:durydevelop/cpp/lib/dpptools.git>
#     |    |
#     |    |lib-mcu\
#     |    |         |dpptools-mcu <git@gitlab.com:durydevelop/cpp/lib-mcu/dpptools-mcu.git>
#     |    |
#     |    |src\
#     |    |
#     |    |src-mcu\
#     |    
#     |dev-tools <git@gitlab.com:durydevelop/dev-tools.git>

print-usage() {
    echo "This script will install Dury Develop Framework."
    echo "Usage: $(basename "$0") [-p <path>] [-h]"
    echo "Options:"
	echo -e "-p, --path <path>\tStart from <path> folder."
    echo -e "-h, --help\t\tPrint this help."
}

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

# Write text line in a file: if does not exist, add it
# $1    ->  shell configuration file update (~/.bashrc, ~/.zshrc, ecc)
# $2    ->  path to add
function write_line_in_file_if_not_exists() {
    if [[ -f $1 ]]; then
        ret=$(grep -xF "$2" $1 || echo "$2" >> $1)
        #if [[ $ret == "" ]]; then
        #    echo -e "\e[33m\"$2\" PATH has been added to $1\e[0m"
        #fi
    fi
}

# Install pkg if does not exists
# $1    ->  pkg name (e.g. smb)
# [$2]    ->  command used to check pkg (e.g. smbpasswd)
function install_if_not_exists() {
	local MISSING=0
	if [[ -z $2 ]]; then
		# 2nd argument not found use dpkg
		RET=$(dpkg -l | grep $1)
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
		echo -e "\e[33m$1 is not installed, wait for installing...\e[0m"
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

#################################### entry-point ####################################

# parse command line
POSITIONAL=()
    while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
            -p|--path)
                echo -e "Forcing $ENV_DDEV_ROOT_PATH to \e[33m$2\e[0m"
                DDEV_ROOT_PATH="$2"
                shift # past argument
                shift # past value
                ;;
            -h|--help)
                print-usage
                exit
            ;;
            *)    # unknown option
				echo "Unkown option: $1"
				print-usage
				exit
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
set -- "${POSITIONAL[@]}" # restore positional parameters

#Check for dependences
install_if_not_exists git
install_if_not_exists build-essential
install_if_not_exists cmake
install_if_not_exists libboost-dev

echo "-- $(basename "$0") Ver. $Version --"

#Check folders structure
CURR_DDEV_ROOT_PATH=$(printenv $ENV_DDEV_ROOT_PATH)
if [[ $CURR_DDEV_ROOT_PATH == "" ]]; then
	## No DDEV_ROOT found
	# set default
	if [[ $DDEV_ROOT_PATH == "" ]]; then
		# No manual entered root path
		echo "Seems DDEV-TOOLS are not installed, use $DEFAULT_DDEV_ROOT_PATH as $ENV_DDEV_ROOT_PATH environment?"
		DDEV_ROOT_PATH=$DEFAULT_DDEV_ROOT_PATH
	else
		# Manual entered root path
		DDEV_ROOT_PATH=$(realpath $DDEV_ROOT_PATH)
		echo "Use $DDEV_ROOT_PATH as $ENV_DDEV_ROOT_PATH environment?"
	fi
	read -p "(Y/n)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		exit 1
	fi
	create_if_not_exists $DDEV_ROOT_PATH
else
	echo "DDEV_ROOT_PATH=$DDEV_ROOT_PATH"
	echo "CURR_DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH"
	if [[ $DDEV_ROOT_PATH != "" ]]; then
		# Manual entered root path
		DDEV_ROOT_PATH=$(realpath $DDEV_ROOT_PATH)
		if [[ $DDEV_ROOT_PATH != $CURR_DDEV_ROOT_PATH ]]; then
			# Different from now
			echo -e -n "Current $ENV_DDEV_ROOT_PATH env is \e[33m$CURR_DDEV_ROOT_PATH\e[0m, you entered \e[33m$DDEV_ROOT_PATH\e[0m "
			echo -n "use it as new $ENV_DDEV_ROOT_PATH environment."
			read -p "(Y/n)" -n 1 -r
			echo
			if [[ $REPLY =~ ^[Nn]$ ]]; then
				exit 1
			fi
			create_if_not_exists $DDEV_ROOT_PATH
			CURR_DDEV_ROOT_PATH=$DDEV_ROOT_PATH
		fi
	else
		DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH
	fi
fi
echo "DDEV_ROOT_PATH=$DDEV_ROOT_PATH"
echo "CURR_DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH"

if [[ ! -d $DDEV_ROOT_PATH ]]; then
    echo -e "\e[33mSomething was wrong, folder <$DDEV_ROOT_PATH> does not exist. Try to use -p option to set new path.\e[0m"
    exit 2
fi
cd $DDEV_ROOT_PATH
echo -e  "DDEV_ROOT is \e[33m$DDEV_ROOT_PATH\e[0m"

DDEV_TOOLS_PATH=$DDEV_ROOT_PATH/dev-tools

## Create folder structure
echo "Create folder structure..."
# cpp
create_if_not_exists "$DDEV_ROOT_PATH/cpp"

# cpp/lib
create_if_not_exists "$DDEV_ROOT_PATH/cpp/lib"

# cpp/lib-mcu
create_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu"

# cpp/src
create_if_not_exists "$DDEV_ROOT_PATH/cpp/src"

# cpp/src-mcu
create_if_not_exists "$DDEV_ROOT_PATH/cpp/src-mcu"

# cpp/src-mcu/rpi
create_if_not_exists "$DDEV_ROOT_PATH/cpp/src-mcu/rpi"

# cpp/src-mcu/arduino
create_if_not_exists "$DDEV_ROOT_PATH/cpp/src-mcu/arduino"

# cpp/src-mcu/attiny85
create_if_not_exists "$DDEV_ROOT_PATH/cpp/src-mcu/attiny85"

## Clone repos
echo "Clone repositories"

# Clone dev-tools
if [[ $1 == "-https" ]]; then
    clone_if_not_exists $DDEV_TOOLS_PATH https://"$GITLAB_ACCESS_TOKEN@"gitlab.com/durydevelop/dev-tools.git
else
    clone_if_not_exists $DDEV_TOOLS_PATH git@gitlab.com:durydevelop/dev-tools.git
fi

# Clone helpers_cmake
clone_if_not_exists "$DDEV_ROOT_PATH/cpp/helpers_cmake" git@gitlab.com:durydevelop/cpp/helpers_cmake.git

# Clone dpptools
if [[ $1 == "-https" ]]; then
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/dpptools" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/dpptools.git
else
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/dpptools" git@gitlab.com:durydevelop/cpp/lib/dpptools.git
fi

# Clone dpptools-mcu
if [[ $1 == "-https" ]]; then
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dpptools-mcu" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib-mcu/dpptools-mcu.git
else
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dpptools-mcu" git@gitlab.com:durydevelop/cpp/lib-mcu/dpptools-mcu.git
fi

# Update environments
echo "Update environments..."

# Create ddev-env
create_if_not_exists $HOME/.ddev
echo "export PATH=$DDEV_TOOLS_PATH:\$PATH 
export $ENV_DDEV_ROOT_PATH=$DDEV_ROOT_PATH
export $ENV_DDEV_TOOLS_PATH=$DDEV_TOOLS_PATH
export $ENV_DDEV_GSOAP_TEMPLATES=$DDEV_TOOLS_PATH/gsoap/templates" > $HOME/.ddev/ddev-env
# Update .profile
write_line_in_file_if_not_exists $HOME/.profile '. "$HOME/.ddev/ddev-env"'
# Reload .profile
echo "Try to reload .profile for shell"
echo "Before reload:"
echo -e "\e[33mENV_DDEV_ROOT_PATH=$(printenv $ENV_DDEV_ROOT_PATH)\e[0m"
echo -e "\e[33mCURR_DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH\e[0m"
#. $HOME/.profile
source ~/.profile
echo "After reload:"
echo -e "\e[33mENV_DDEV_ROOT_PATH=$(printenv $ENV_DDEV_ROOT_PATH)\e[0m"
echo -e "\e[33mCURR_DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH\e[0m"
if [[ $(printenv $ENV_DDEV_ROOT_PATH) != $CURR_DDEV_ROOT_PATH ]]; then
	echo -e "\e[38;5;9mYou need to restart your shell. Close and reopen it or type \"source ~/.profile\" command.\e[0m"
fi

## optional
#install_if_not_exists qbase5-dev
#install_if_not_exists libopencv-dev
