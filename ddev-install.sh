#! /bin/bash

# TODO: Check environments using array

Version=1.0.4
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
#     |    |    |_temp
#     |    |    |_todo
#     |    |    |libdpp <git@gitlab.com:durydevelop/cpp/lib/libdpp.git>
#     |    |    |mcu\
#     |    |         |ddigitalio     <git@gitlab.com:durydevelop/cpp/lib/mcu/ddigitalio.git>
#     |    |         |dmcomm         <git@gitlab.com:durydevelop/cpp/lib/mcu/dmcomm.git>
#     |    |         |dservo         <git@gitlab.com:durydevelop/cpp/lib/mcu/dservo.git>
#     |    |         |dmenu          <git@gitlab.com:durydevelop/cpp/lib/mcu/dmenu.git>
#     |    |         |ddcmotorwheels <git@gitlab.com:durydevelop/cpp/lib/mcu/ddcmotorwheels.git>
#     |    |
#     |    |src\
#     |    
#     |dev-tools <git@gitlab.com:durydevelop/dev-tools.git>

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
# $1 pkg name (es. git)
function install_if_not_exists() {
	if ! command -v $1 &> /dev/null; then
		echo ""
		echo -e "\e[33m$1 is not installed, wait for installing...\e[0m"
		sudo apt-get install -y $1;
		if [ $? -eq 0 ]; then
			echo -e "\e[32mgit install done\e[0m"
		else
			echo -e "\e[1;41mgit install failed\e[0m"
			exit 1
		fi

		sudo apt-get install -y -f
		if [ $? -eq 0 ]; then
			echo -e "\e[32mMissed dependency install complete\e[0m"
		else
			echo -e "\e[1;41mMissed dependency install failed\e[0m"
		exit 1
    fi
	else
		echo -e "\e[32m OK\e[0m"
	fi
}

#################################### entry-point ####################################
echo "-- $(basename "$0") Ver. $Version --"

# Check for git exists
echo -n -e "Checking for \e[33mgit\e[0m command"
install_if_not_exists git

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
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
set -- "${POSITIONAL[@]}" # restore positional parameters

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
	if [[ $DDEV_ROOT_PATH != "" ]]; then
		# Manual entered root path
		DDEV_ROOT_PATH=$(realpath $DDEV_ROOT_PATH)
		if [[ $DDEV_ROOT_PATH != $CURR_DDEV_ROOT_PATH ]]; then
			# Different from now
			echo -n "Current $ENV_DDEV_ROOT_PATH env is \e[33m$CURR_DDEV_ROOT_PATH\e[0m, you entered \e[33m$DDEV_ROOT_PATH\e[0m "
			echo -n "use it as new $ENV_DDEV_ROOT_PATH environment."
			read -p "(Y/n)" -n 1 -r
			echo
			if [[ $REPLY =~ ^[Nn]$ ]]; then
				exit 1
			fi
			create_if_not_exists $DDEV_ROOT_PATH
		fi
	else
		DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH
	fi
fi

if [[ ! -d $DDEV_ROOT_PATH ]]; then
    echo -e "\e[33mSomething was wrong, folder $DEV_ROOT does not exist.\e[0m"
    exit 2
fi
cd $DDEV_ROOT_PATH
echo -e  "DDEV_ROOT is \e[33m$DDEV_ROOT_PATH\e[0m"

DDEV_TOOLS_PATH=$DDEV_ROOT_PATH/dev-tools

## Start creating folders
# dev-tools
if [[ $1 == "-https" ]]; then
    clone_if_not_exists $DDEV_TOOLS_PATH https://"$GITLAB_ACCESS_TOKEN@"gitlab.com/durydevelop/dev-tools.git
else
    clone_if_not_exists $DDEV_TOOLS_PATH git@gitlab.com:durydevelop/dev-tools.git
fi

# cpp
create_if_not_exists "$DDEV_ROOT_PATH/cpp"

# cpp/helpers_cmake
clone_if_not_exists "$DDEV_ROOT_PATH/cpp/helpers_cmake" git@gitlab.com:durydevelop/cpp/helpers_cmake.git

# cpp/lib
create_if_not_exists "$DDEV_ROOT_PATH/cpp/lib"

# cpp/src
create_if_not_exists "$DDEV_ROOT_PATH/cpp/src"

# cpp/_temp
create_if_not_exists "$DDEV_ROOT_PATH/cpp/_temp"

# cpp/_todo
create_if_not_exists "$DDEV_ROOT_PATH/cpp/_todo"

# cpp/lib/libdpp
if [[ $1 == "-https" ]]; then
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/libdpp" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com/durydevelop/cpp/lib/libdpp.git
else
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/libdpp" git@gitlab.com:durydevelop/cpp/lib/libdpp.git
fi

# cpp/lib/mcu
create_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu"
if [[ $1 == "-https" ]]; then
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/ddigitalio" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/ddigitalio.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/dmcomm" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/dmcomm.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/dservo" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/dservo.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/dmenu" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/dmenu.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/ddcmotorwheels" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/ddcmotorwheels.git
else
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/ddigitalio" git@gitlab.com:durydevelop/cpp/lib/mcu/ddigitalio.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/dmcomm" git@gitlab.com:durydevelop/cpp/lib/mcu/dmcomm.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/dservo" git@gitlab.com:durydevelop/cpp/lib/mcu/dservo.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/dmenu" git@gitlab.com:durydevelop/cpp/lib/mcu/dmenu.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/mcu/ddcmotorwheels" git@gitlab.com:durydevelop/cpp/lib/mcu/ddcmotorwheels.git
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
. $HOME/.profile
if [[ $(printenv $ENV_DDEV_ROOT_PATH) == "" ]]; then
	echo -e "\e[33mYou need to restart your shell. Close and reopen it or type \"source ~/.profile\" command.\e[0m"
fi
