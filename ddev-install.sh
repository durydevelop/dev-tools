#! /bin/bash
Version=1.0.1
DEV_TOOLS="dev-tools"

# TODO:
# _Add dev-tools/qt to PATH
# _Add dev-tools/gsoap to PATH
# _Set DDEV_GSOAP_TEMPLATES to env

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

gitlab_access_token="read-only:XRQgs6iGq8TQ6xvoDmDk"

# Create $1 folder if does not exists
function create_if_not_exists() {
    echo -n -e "Checking for \e[33m$1\e[0m folder "
    if [[ ! -d "$1" ]]; then
        echo -e "\e[33mcreate\e[0m"
        mkdir $1
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

# Update PATH environment
# $1    ->  shell configuration file update (~/.bashrc, ~/.zshrc, ecc)
# $2    ->  path to add
function update_path() {
    if [[ -f $1 ]]; then
        ret=$(grep -xF "export PATH=\"$2:\$PATH\"" $1 || echo "export PATH=\"$2:\$PATH\"" >> $1)
        if [[ $ret == "" ]]; then
            echo -e "\e[33m\"$2\" PATH has been added to $1\e[0m"
        fi
    fi
}

#################################### entry-point ####################################
echo "-- $(basename "$0") Ver. $Version --"

# Check for git exists
echo -n -e "Checking for \e[33mgit\e[0m command"
if ! command -v git &> /dev/null; then
    echo ""
    echo -e "\e[33mGit is not installed, wait for installing...\e[0m"
    sudo apt-get install -y git;
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

# Be sure to start in a right folder (folders stucture should be start under a folder named "Dev")
curr_dir=$(basename "$PWD")
if [[ $curr_dir == $DEV_TOOLS ]]; then
    cd ..
fi
curr_dir=$(basename "$PWD")

if [[ -d $(pwd)/Dev ]]; then
    cd Dev
elif [[ ! $curr_dir == "Dev" && ! $curr_dir == "dev" ]]; then
    echo "You are not in a folder named \"Dev\", if you continue, the folder will be created (if does not exist) and install procedure starts from there. "
    read -p "Continue (Y/n)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        exit 1
    fi
    create_if_not_exists "Dev"
    cd Dev
fi

# Set Dev folder as DEV_ROOT
DEV_TOOLS_PATH="$(pwd)/$DEV_TOOLS"

## Start creating folders

# dev-tools
if [[ $1 == "-https" ]]; then
    clone_if_not_exists dev-tools https://"$gitlab_access_token@"gitlab.com/durydevelop/dev-tools.git
else
    clone_if_not_exists dev-tools git@gitlab.com:durydevelop/dev-tools.git
fi

# cpp
create_if_not_exists "cpp"
cd cpp

# helpers_cmake
clone_if_not_exists helpers_cmake git@gitlab.com:durydevelop/cpp/helpers_cmake.git

# lib
create_if_not_exists "lib"

# src
create_if_not_exists "src"
cd lib

# temp
create_if_not_exists "_temp"

# todo
create_if_not_exists "_todo"

# libdpp
if [[ $1 == "-https" ]]; then
    clone_if_not_exists libdpp https://"$gitlab_access_token@"gitlab.com/durydevelop/cpp/lib/libdpp.git
else
    clone_if_not_exists libdpp git@gitlab.com:durydevelop/cpp/lib/libdpp.git
fi

# mcu
create_if_not_exists "mcu"
cd mcu
if [[ $1 == "-https" ]]; then
    clone_if_not_exists ddigitalio https://"$gitlab_access_token@"gitlab.com:durydevelop/cpp/lib/mcu/ddigitalio.git
    clone_if_not_exists dmcomm https://"$gitlab_access_token@"gitlab.com:durydevelop/cpp/lib/mcu/dmcomm.git
    clone_if_not_exists dservo https://"$gitlab_access_token@"gitlab.com:durydevelop/cpp/lib/mcu/dservo.git
    clone_if_not_exists dmenu https://"$gitlab_access_token@"gitlab.com:durydevelop/cpp/lib/mcu/dmenu.git
    clone_if_not_exists ddcmotorwheels https://"$gitlab_access_token@"gitlab.com:durydevelop/cpp/lib/mcu/ddcmotorwheels.git
else
    clone_if_not_exists ddigitalio git@gitlab.com:durydevelop/cpp/lib/mcu/ddigitalio.git
    clone_if_not_exists dmcomm git@gitlab.com:durydevelop/cpp/lib/mcu/dmcomm.git
    clone_if_not_exists dservo git@gitlab.com:durydevelop/cpp/lib/mcu/dservo.git
    clone_if_not_exists dmenu git@gitlab.com:durydevelop/cpp/lib/mcu/dmenu.git
    clone_if_not_exists ddcmotorwheels git@gitlab.com:durydevelop/cpp/lib/mcu/ddcmotorwheels.git
fi

# Chech for PATH environment
echo -n "Checking for PATH "
# Add ~/Dev/dev-tools to PATH if needed
if [[ -d $DEV_TOOLS_PATH ]]; then
    ret=$(echo $PATH | grep $DEV_TOOLS_PATH)
    if [[ $ret == "" ]]; then
        echo -e "\e[1;41m$DEV_TOOLS_PATH is not set\e[0m"
        # Update .bashrc
        update_path ~/.bashrc $DEV_TOOLS_PATH
        update_path ~/.zshrc $DEV_TOOLS_PATH
        echo -e "\e[33mPATH env is not loaded, please run \"source ~/.$(basename $SHELL)rc\" command or close/re-open shell to reload PATH environment\e[0m"
    else
        echo -e "\e[32mOK\e[0m"
    fi
else
    echo -e "\e[33mMay be something wrong, folder $DEV_TOOLS_PATH does not exist.\e[0m"
fi

echo ""
if [[ error_msg != "" ]]; then
    echo -e "\e[1;41m$error_msg\e[0m"
fi
