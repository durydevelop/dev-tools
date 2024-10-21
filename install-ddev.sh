#! /bin/bash

# TODO: Check environments using array

Version=1.0.8
GITLAB_ACCESS_TOKEN="read-only:XRQgs6iGq8TQ6xvoDmDk"
ENV_DDEV_GSOAP_TEMPLATES="DDEV_GSOAP_TEMPLATES"
ENV_DDEV_ROOT_PATH="DDEV_ROOT"
ENV_DDEV_TOOLS_PATH="DDEV_TOOLS"

# Result structure:
# Dev\
#     |cpp\
#     |    |helpers_cmake\  <git@gitlab.com:durydevelop/cpp/helpers_cmake.git>
#     |    |
#     |    |lib\
#     |    |    	 |dpplib <git@gitlab.com:durydevelop/cpp/lib/dpptools.git>
#     |    |
#     |    |lib-mcu\
#     |    |         |arduino-lib-oled
#     |    |         |dpplib-mcu
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
	echo -e "-p, --path <path>\tInstall in <path> folder."
    echo -e "-h, --help\t\tPrint this help."
}

#################################### entry-point ####################################

# Full path of the current script
THIS=`readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo $0`

# The directory where current script resides
DIR=`dirname "${THIS}"`

# Include script library ('Dot' means 'source', i.e. 'include':)
. "$DIR/lib.sh"

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

## Main dependences
install_if_not_exists git
install_if_not_exists cmake
install_if_not_exists build-essential
install_if_not_exists libboost-dev
install_if_not_exists libopencv-dev

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

echo "-- $(basename "$0") Ver. $Version --"
if [ $(id -u) -ne 0 ]; then
  # No sudo
  HOME="$HOME"
else
	#echo -e "HOME before = $HOME"
	HOME="/home/$SUDO_USER"
	#echo -e "HOME after = $HOME"
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

# cpp/helpers_cmake
create_if_not_exists "$DDEV_ROOT_PATH/cpp/helpers_cmake"

# cpp/lib
create_if_not_exists "$DDEV_ROOT_PATH/cpp/lib"

# cpp/src
create_if_not_exists "$DDEV_ROOT_PATH/cpp/src"

# cpp/lib-mcu
create_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu"

# cpp/src-mcu
create_if_not_exists "$DDEV_ROOT_PATH/cpp/src-mcu"

## Clone repo
echo "Clone repositories"

# Clone dev-tools
if [[ $1 == "-https" ]]; then
    clone_if_not_exists $DDEV_TOOLS_PATH https://"$GITLAB_ACCESS_TOKEN@"gitlab.com/durydevelop/dev-tools.git
else
    clone_if_not_exists $DDEV_TOOLS_PATH git@gitlab.com:durydevelop/dev-tools.git
fi

# Clone helpers_cmake
clone_if_not_exists "$DDEV_ROOT_PATH/cpp/helpers_cmake" git@gitlab.com:durydevelop/cpp/helpers_cmake.git

# Clone dpplib
if [[ $1 == "-https" ]]; then
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/dpplib" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com/durydevelop/cpp/lib/dpptools.git
else
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/dpplib" git@gitlab.com:durydevelop/cpp/lib/dpptools.git
fi

# Clone mcu libs
if [[ $1 == "-https" ]]; then
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/ddigitalio" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/ddigitalio.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dmcomm" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/dmcomm.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dservo" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/dservo.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dmenu" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/dmenu.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/ddcmotorwheels" https://"$GITLAB_ACCESS_TOKEN@"gitlab.com:durydevelop/cpp/lib/mcu/ddcmotorwheels.git
else
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/ddigitalio" git@gitlab.com:durydevelop/cpp/lib/mcu/ddigitalio.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dmcomm" git@gitlab.com:durydevelop/cpp/lib/mcu/dmcomm.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dservo" git@gitlab.com:durydevelop/cpp/lib/mcu/dservo.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/dmenu" git@gitlab.com:durydevelop/cpp/lib/mcu/dmenu.git
    clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib-mcu/ddcmotorwheels" git@gitlab.com:durydevelop/cpp/lib/mcu/ddcmotorwheels.git
fi

# Clone Qt Advanced Docking
clone_if_not_exists "$DDEV_ROOT_PATH/cpp/lib/Qt-Advanced-Docking-System" https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git

# Update environments
echo "Update environments..."

# Create ddev-env
create_if_not_exists $HOME/.ddev
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
