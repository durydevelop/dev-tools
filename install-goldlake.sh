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

# Install packet if not exists
# $1 packet name
function install_if_not_exists() {
    echo -n -e "Checking for \e[33m$1\e[0m command"
    if ! command -v git &> /dev/null; then
	echo ""
	echo -e "\e[33m$1 is not installed, wait for installing...\e[0m"
	sudo apt-get install -y $1;
	if [ $? -eq 0 ]; then
	    echo -e "\e[32m$1 install done\e[0m"
	else
	    echo -e "\e[1;41m$1 install failed\e[0m"
	    exit 1
	fi
	
	# Check for missing dependencies
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

create_if_not_exists $DDEV_ROOT/cpp/src-mcu/rpi/goldlake
clone_if_not_exists $DDEV_ROOT/cpp/src-mcu/rpi/goldlake/goldlake-frontend git@gitlab.com:durydevelop/cpp/src-mcu/rpi/goldlake/goldlake-frontend.git
if [[ ! -d $DDEV_ROOT/cpp/lib/emsdk ]]; then
	echo -n "emsdk is not installed, install it? "
	read -p "(Y/n)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		exit 1
	fi
	install_if_not_exists bzip2
	clone_if_not_exists $DDEV_ROOT/cpp/lib/emsdk https://github.com/emscripten-core/emsdk.git
	cd $DDEV_ROOT/cpp/lib/emsdk
	./emsdk install latest
fi
