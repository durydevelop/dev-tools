#/bin/bash

echo -n -e "\e[33mInstall libraries if needed...\e[0m"
echo
sudo apt-get install -y libsdl1.2-dev libsdl-image1.2-dev libsdl-ttf2.0-dev
if [ $? -eq 0 ]; then
    echo -e "\e[32mInstalled\e[0m"
else
    echo -e "\e[1;41mLibraries install failed\e[0m"
exit 1
fi
echo -n -e "\e[33mCloning GUISlice...\e[0m"
echo
git clone https://github.com/ImpulseAdventure/GUIslice
if [ ! $? -eq 0 ]; then
    echo -e "\e[1;41mCloning failed\e[0m"
    exit 1
fi

echo -e "\e[32mInstall finished. Do You want to try to compile and execute sdl1 test?\e[0m"    
read -p "Continue (Y/n)" -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 1
fi
cd GUIslice/examples/linux
make test_sdl1
sudo ./test_sdl1
