#! /bin/bash

# Create folder if does not exists
# $1	->	folder path
# $2	->	user to impersonate
function create_if_not_exists() {
    if [[ ! -d "$1" ]]; then
	if [[ $2 ]]; then
	    sudo -u $2 mkdir -p $1
	else
	    mkdir -p $1
	fi
	
        if [[ ! -d "$1" ]]; then
            echo -e "\e[31mImpossibile creare $1\e[0m"
            DIR_DONE=false
	    exit 1
        fi
        if [[ $DIR_ADDED != true ]]; then
            echo
        fi
	
        echo -e "$1 \e[32mCREATA\e[0m"
        DIR_ADDED=true
    fi
    
    DIR_DONE=true
}

# Add a permanent share to fstab
# $1    ->  Windows share       //vsgiove/prodig
# $2    ->  Local path          /mnt/vsgiove/prodig
# $3    ->  Username
# $4    ->  Password
# $5    ->  Domain
function add_share_if_not_exists() {
    if [[ -f /etc/fstab ]]; then
	# Test mount
	if ! mountpoint -q $2; then
	    # LOCAL_PATH is not mounted, try to share
	    test_share $1 $3 $4 $5
	    if [[ $? == 0 ]]; then
		sed -i '/$REMOTE_PATH/d' /etc/fstab # delete entry
	    else
		echo -e "\e[31m...non continuo, verifica\e[0m"
		exit 1
	    fi
	fi
	# Create folder and add to fstab
	create_if_not_exists $2
        SHARE_ENTRY="$1 $2 cifs username=$3,password=$4,domain=$5,file_mode=0666,dir_mode=0777,uid=1000,gid=1000 0 0"
        ret=$(grep -xF "$SHARE_ENTRY" /etc/fstab || echo $SHARE_ENTRY >> /etc/fstab)
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
	exit 1
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
        echo -e "\e[32mTest riuscito, smonto ed elimino...\e[0m"
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

# Write text line in a file: if does not exist, add it
# $1    ->  filename
# $2    ->  string to add as line
function write_line_in_file_if_not_exists() {
    if [[ -f $1 ]]; then
        ret=$(grep -xF "$2" $1 || echo "$2" >> $1)
    else
        echo -e "\e[31m $1 NON TROVATO\e[0m"
	exit 1
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

########## Entry point ##########
if [ $(id -u) -ne 0 ]; then
  echo -e "\e[41mDevi sudare se vuoi usare questo script...\e[0m"
  exit 1
fi

source install-durylab-share-rockpi.sh

# DuryFinder Install
echo -n "Installazione DuryFinder..."
MOUNT_POINT="/mnt/duryfinder/app"
if ! mountpoint -q $MOUNT_POINT; then
    echo -e "\e[31mLa dir $MOUNT_POINT non è montata"
    echo -e "riavvia la stazione e riprova\e[0m"
fi
DIR_DONE=false
DIR_ADDED=false
create_if_not_exists "/home/$SUDO_USER/DuryCorp/DuryFinder" $SUDO_USER
sudo -u $SUDO_USER cp -r $MOUNT_POINT/rockpi/* /home/$SUDO_USER/DuryCorp/DuryFinder
#mv /home/$SUDO_USER/DuryCorp/DuryFinder/libopencv* /lib/arm-linux-gnueabihf/
#mv /home/$SUDO_USER/DuryCorp/DuryFinder/libqtadvanceddocking* /lib/arm-linux-gnueabihf/
#sudo ln /usr/lib/aarch64-linux-gnu/libwebp.so /usr/lib/aarch64-linux-gnu/libwebp.so.6
#sudo ln /usr/lib/aarch64-linux-gnu/libtiff.so /usr/lib/aarch64-linux-gnu/libtiff.so.5

if [[ $DIR_ADDED == true ]]; then
    echo -e "\e[32mOK\e[0m"
elif [[ $DIR_DONE == true ]]; then
    echo -e "\e[32mOK\e[0m"
fi

# Set file mode execute
chmod +x /home/$SUDO_USER/DuryCorp/DuryFinder/DuryFinder

# DuryFinder lib
#install_if_not_exists "libgdcm3.0"
#install_if_not_exists "libgdal28"
#install_if_not_exists "libtbb2"
install_if_not_exists "qt6-base-dev"

# sudo apt-get autoremove -y

# DuryLauncher Install
echo -n "Installazione DuryLauncher..."
DIR_DONE=false
DIR_ADDED=false
create_if_not_exists "/home/$SUDO_USER/DuryCorp/DuryLauncher" $SUDO_USER
sudo -u $SUDO_USER cp -r /mnt/durylauncher/app/rockpi/* /home/$SUDO_USER/DuryCorp/DuryLauncher
#sudo -u $SUDO_USER cp /home/$SUDO_USER/DuryCorp/DuryLauncher/launch/desktop/* /home/$SUDO_USER/Desktop
if [[ $DIR_ADDED == true ]]; then
    echo -e "\e[32mOK\e[0m"
elif [[ $DIR_DONE == true ]]; then
    echo -e "\e[32mOK\e[0m"
fi

# Set file mode execute
chmod +x /home/$SUDO_USER/DuryCorp/DuryLauncher/durylauncher.sh
chmod +x /home/$SUDO_USER/DuryCorp/DuryLauncher/durylauncher
chmod +x /home/$SUDO_USER/DuryCorp/DuryLauncher/launch/*.sh

# Add to autorun
#write_line_in_file_if_not_exists /etc/xdg/lxsession/LXDE-pi/autostart "@/home/$SUDO_USER/DuryCorp/DuryLauncher/durylauncher.sh"

echo "Configurazione cups"
install_if_not_exists cups lpadmin true
# Disable auto discovery
systemctl stop cups-browsed
systemctl disable cups-browsed
echo -e "\e[32mOK\e[0m"

#echo "Installazione Stampante Zebra"
#sudo -u $SUDO_USER "$(pwd)"/install-zebra.sh
