#!/bin/bash

## Use lib.sh as functions library
# Full path of the current script
THIS=`readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo $0`
# The directory where current script resides
DIR=`dirname "${THIS}"`
# Include script library ('Dot' means 'source', i.e. 'include':)
echo "Using $DIR/lib.sh"
source "$DIR/lib.sh"

#################################### entry-point ####################################
EMSDK_ROOT=$DDEV_ROOT/cpp/lib/emsdk

dir_create_if_not_exists $DDEV_ROOT/cpp/src-mcu/rpi/goldlake
git_clone_if_not_exists $DDEV_ROOT/cpp/src-mcu/rpi/goldlake git@gitlab.com:durydevelop/cpp/src-mcu/rpi/goldlake.git

if [[ ! -d $EMSDK_ROOT ]]; then
	echo -n "emsdk is not installed, install it? "
	read -p "(Y/n)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		exit 1
	fi
	install_if_not_exists bzip2
	git_clone_if_not_exists $EMSDK_ROOT https://github.com/emscripten-core/emsdk.git
fi

if [[ -d $EMSDK_ROOT ]]; then
	# Only if installed
	echo -e "\e[33mUpdate and activate emsdk\e[0m"
	EMSDK_QUIET=1
	cd $EMSDK_ROOT
	./emsdk install latest
	./emsdk activate latest --permanent &> /dev/null
	write_line_in_file_if_not_exists "$HOME/.profile" "EMSDK_QUIET=1 . $EMSDK_ROOT/emsdk_env.sh"
	if [[ $(printenv EMSDK) == "" ]]; then
		echo -e "\e[38;5;9mYou need to restart your shell. Close and reopen it or type \"source ~/.profile\" command.\e[0m"
	fi
fi
install_if_not_exists mesa-common-dev
install_if_not_exists libx11-dev
install_if_not_exists libxrandr-dev
install_if_not_exists libxinerama-dev
if linux
	install_if_not_exists libxcursor-dev
fi
install_if_not_exists libxi-dev
