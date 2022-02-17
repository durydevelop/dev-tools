#!/bin/bash

# REMEMBER TO UNCOMMENT THE CONFIGURE LINE FOR YOUR TARGET PLATFORM.
# ... and comment out the default of course.

#
#  This is the new GCC version to install.
#
VERSION=10.2.0

#
#  These are the languages the new compiler should support.
#
LANG=c,c++,fortran

#
#  For any computer with less than 2GB of memory.
#
#if [ -f /etc/dphys-swapfile ]; then
#  sudo sed -i 's/^CONF_SWAPSIZE=[0-9]*$/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
#  sudo /etc/init.d/dphys-swapfile restart
#fi

if [ -d gcc-$VERSION ]; then
  cd gcc-$VERSION
  rm -rf obj
else
  echo "Download source tree ..."
  wget ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-$VERSION/gcc-$VERSION.tar.xz
  echo "Uncompress source tree ..."
  tar xf gcc-$VERSION.tar.xz
  rm -f gcc-$VERSION.tar.xz
  cd gcc-$VERSION
  contrib/download_prerequisites
fi
mkdir -p obj
cd obj

#
#  Now run the ./configure which must be checked/edited beforehand.
#  Uncomment the sections below depending on your platform.  You may build
#  on a Pi3 for a target Pi Zero by uncommenting the Pi Zero section.
#  To alter the target directory set --prefix=<dir>
#  For a very quick build try: --disable-bootstrap
#

# x86_64
#../configure --disable-multilib --enable-languages=$LANG

# AArch64 Pi4 running Raspberry Pi OS 64-bit
#../configure --enable-languages=$LANG --with-cpu=cortex-a72

# Pi Zero
#../configure --enable-languages=$LANG --with-cpu=arm1176jzf-s \
#  --with-fpu=vfp --with-float=hard --build=arm-linux-gnueabihf \
#  --host=arm-linux-gnueabihf --target=arm-linux-gnueabihf

# Pi3+, Pi3, Pi4 in 32-bit mode
../configure --enable-languages=$LANG --with-cpu=cortex-a53 \
  --with-fpu=neon-fp-armv8 --with-float=hard --build=arm-linux-gnueabihf \
  --host=arm-linux-gnueabihf --target=arm-linux-gnueabihf

# Old Pi2
#../configure --enable-languages=$LANG --with-cpu=cortex-a7 \
#  --with-fpu=neon-vfpv4 --with-float=hard --build=arm-linux-gnueabihf \
#  --host=arm-linux-gnueabihf --target=arm-linux-gnueabihf

#
#  Now build GCC which will take a long time.  This could range from
#  3.5 hours on a 4GB Pi4 up to about 50 hours on a Pi Zero.  It can be
#  left to complete overnight (or over the weekend for a Pi Zero :-)
#  The most likely causes of failure are lack of disk space, lack of
#  swap space or memory, or the wrong configure section uncommented.
#  The new compiler is placed in /usr/local/bin, the existing compiler remains
#  in /usr/bin and may be used by giving its version gcc-6 (say).
#
if make -j `nproc`
then
  echo
  read -p "Do you wish to install the new GCC (y/n)? " yn
  case $yn in
   [Yy]* ) sudo make install ;;
     * ) exit ;;
  esac
fi
