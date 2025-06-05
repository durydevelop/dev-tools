#! /bin/bash

# TODO: Check environments using array

Version=2.0.1
ENV_DDEV_GSOAP_TEMPLATES="DDEV_GSOAP_TEMPLATES"
ENV_DDEV_ROOT_PATH="DDEV_ROOT"
ENV_DDEV_TOOLS_PATH="DDEV_TOOLS"

# Result structure:
# Dev\
#     |cpp\
#     |    |helpers_cmake\  <https://github.com/durydevelop/helpers_cmake.git>
#     |    |
#     |    |lib\
#     |    |    	 |dpplib <git@gitlab.com:durydevelop/cpp/lib/dpptools.git>
#     |    |    	 |dwebsocket <https://github.com/durydevelop/dwebsocket.git>
#     |    |         |Qt-ads <https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git>
#     |    |
#     |    |lib-mcu\
#     |    |         |dpplib-mcu <https://github.com/durydevelop/dpplibmcu.git>
#     |    |         |raywui <https://github.com/durydevelop/raywui.git>
#     |    |
#     |    |src\
#     |    |
#     |    |src-mcu\
#     |    
#     |dev-tools <https://github.com/durydevelop/dev-tools.git>

print-usage() {
    echo "This script will install Dury Develop Framework."
    echo "Usage: $(basename "$0") [-p <path>] [-h]"
    echo "Options:"
	echo -e "-p, --path <path>\tInstall in <path> folder."
    echo -e "-h, --help\t\tPrint this help."
}

################################### Functions ####################################
# Install pkg if does not exists
# $1	->  pkg name (e.g. smb)
# [$2]	->  alternative command (to dpkg) used for installed check (e.g. smbpasswd to check samba)
# return 1 on success otherwise 0
# How to check return value:
#if [[ $() == 0 ]]; then
#	echo ""
#	echo -e -n "\e[1;41m$1 install failed\e[0m"
#fi
function install_if_not_exists() {
	local MISSING=0
	if [[ -z $2 ]]; then
		# 2nd argument not found use dpkg
		if [[ MSYS ]]; then
			# MSYS2: use pacman
			RET=$(pacman -Qs $1)
		else
			# Linux: search for "$1 " or "$1:" (for lib like libboost-dev:amd64)
			RET=$(dpkg -l | grep "$1 \|$1:")
		fi
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
			return 1
		fi
		if [[ MSYS ]]; then
			pacman -S $1 --noconfirm
		else
			sudo apt-get install -y $1
		fi
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

# Parse command line
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

## Main info
echo "-- $(basename "$0") Ver. $Version --"
if [ $(id -u) -ne 0 ]; then
  # No sudo
  HOME="$HOME"
else
	#echo -e "HOME before = $HOME"
	HOME="/home/$SUDO_USER"
	#echo -e "HOME after = $HOME"
fi
if [[ "$(uname -s)" =~ ^MSYS_NT.* ]]; then
	MSYS=true
    echo "MSYS environment"
else
	MSYS=false
    #echo "Not in MSYS"
fi

## Main dependences
install_if_not_exists git
install_if_not_exists cmake
install_if_not_exists build-essential
install_if_not_exists libboost-dev
install_if_not_exists libopencv-dev
install_if_not_exists libgl1-mesa-dev

## Qt dependences
# possible:
# qt6-default
# qt6-base-dev
# qt6-base-private-dev
# qt6-tools-dev
# libqt6svg6
# qt6-qtdeclarative
if [[ $(apt-cache search --names-only qt6-base-dev) != "" ]]; then
	install_if_not_exists qt6-base-dev
elif [[ $(apt-cache search --names-only qtbase5-dev) != "" ]]; then
	install_if_not_exists qtbase5-dev
elif [[ $(apt-cache search --names-only qt5-base-dev) != "" ]]; then
	install_if_not_exists qt5-base-dev
elif [[ $(apt-cache search --names-only qbase5-dev) != "" ]]; then
	install_if_not_exists qbase5-dev
fi
if [[ $() == 0 ]]; then
	echo ""
	echo -e -n "\e[1;41m$1 install failed, continue?\e[0m"
	read -p "(Y/n)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		exit 1
	fi
fi

DEFAULT_DDEV_ROOT_PATH="$HOME/Dev"
echo -e "DEFAULT_DDEV_ROOT_PATH=$DEFAULT_DDEV_ROOT_PATH"

#Check folders structure
CURR_DDEV_ROOT_PATH=$(printenv $ENV_DDEV_ROOT_PATH)
if [[ $CURR_DDEV_ROOT_PATH == "" ]]; then
	## No DDEV_ROOT found
	# set default
	if [[ $DDEV_ROOT_PATH == "" ]]; then
		# No manual entered root path
		echo "Seems DDEV-TOOLS are not installed, use $DEFAULT_DDEV_ROOT_PATH as ENV_DDEV_ROOT_PATH environment?"
		DDEV_ROOT_PATH=$DEFAULT_DDEV_ROOT_PATH
	else
		# Manual entered root path
		DDEV_ROOT_PATH=$(realpath $DDEV_ROOT_PATH)
		echo "Use $DDEV_ROOT_PATH as $ENV_DDEV_ROOT_PATH environment?"
	fi
	read -p "(Y/n)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		read -p "New path: " -r
		if [[ $REPLY = "" ]]; then
			exit 1
		else
			DDEV_ROOT_PATH=$(realpath $REPLY)
		fi
	fi
	dir_create_if_not_exists $DDEV_ROOT_PATH
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
			dir_create_if_not_exists $DDEV_ROOT_PATH
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
dir_create_if_not_exists "$DDEV_ROOT_PATH/cpp"

# cpp/helpers_cmake
dir_create_if_not_exists "$DDEV_ROOT_PATH/cpp/helpers_cmake"

# cpp/lib
dir_create_if_not_exists "$DDEV_ROOT_PATH/cpp/lib"

# cpp/src
dir_create_if_not_exists "$DDEV_ROOT_PATH/cpp/src"

# cpp/lib-mcu
dir_create_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu"

# cpp/src-mcu
dir_create_if_not_exists "$DDEV_ROOT_PATH/cpp/src-mcu"

## Clone repositories
echo "Clone repositories"

# Clone dev-tools
git_clone_if_not_exists $DDEV_TOOLS_PATH https://github.com/durydevelop/dev-tools.git

# Clone helpers_cmake
git_clone_if_not_exists "$DDEV_ROOT_PATH/cpp/helpers_cmake" https://github.com/durydevelop/helpers_cmake.git

## cpp/lib
# Clone dpplib
git_clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/dpplib" https://github.com/durydevelop/dpplib.git
# Clone dwebsocket
git_clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/dwebsocket" https://github.com/durydevelop/dwebsocket.git
# Clone Qt Advanced Docking
git_clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/Qt-Advanced-Docking-System" https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git

## cpp/lib-mcu
# Clone dpplibmcu
git_clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dpplibmcu" https://github.com/durydevelop/dpplibmcu.git
# Clone raywui
git_clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/raywui" https://github.com/durydevelop/raywui.git

# Update environments
echo "Update environments..."

# Create ddev-env
dir_create_if_not_exists $HOME/.ddev
echo "
export PATH=$DDEV_TOOLS_PATH:\$PATH 
export $ENV_DDEV_ROOT_PATH=$DDEV_ROOT_PATH
export $ENV_DDEV_TOOLS_PATH=$DDEV_TOOLS_PATH
export $ENV_DDEV_GSOAP_TEMPLATES=$DDEV_TOOLS_PATH/gsoap/templates
" > $HOME/.ddev/ddev-env

# Update .shell file
if [[ -f "$HOME/.bashrc" ]]; then
	echo "Update .bashrc"
	write_line_in_file_if_not_exists $HOME/.bashrc '. "$HOME/.ddev/ddev-env"'
	source $HOME/.bashrc
elif [[ -f "$HOME/.zshrc" ]]; then
	echo "Update .zshrc"
	write_line_in_file_if_not_exists $HOME/.zshrc '. "$HOME/.ddev/ddev-env"'
	source $HOME/.zshrc
else
	echo "Update .profile"
	write_line_in_file_if_not_exists $HOME/.profile '. "$HOME/.ddev/ddev-env"'
	source $HOME/.profile
fi

if [[ $(printenv $ENV_DDEV_ROOT_PATH) != $CURR_DDEV_ROOT_PATH ]]; then
	echo -e "\e[38;5;9mYou need to restart your shell. Close and reopen it or type \"source ~/.profile\" or \"source ~/.zprofile\" (if you use zsh).\e[0m"
fi
