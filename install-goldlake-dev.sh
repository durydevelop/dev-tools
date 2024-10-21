#! /bin/bash

# Include script library ('Dot' means 'source', i.e. 'include':)
. "$DIR/lib.sh"

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

if [[ ! -d $EMSDK_ROOT ]]; then
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
install_if_not_exists libxcursor
install_if_not_exists libxi-dev
