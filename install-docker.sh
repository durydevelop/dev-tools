#! /bin/bash

sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get install ca-certificates curl gnupg lsb-release -y
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo usermod -aG docker $USER

echo "now need to reboot"

# sudo apt-get install docker-compose-plugin
docker run hello-world
sudo apt-get update && sudo apt-get upgrade docker
apt-cache policy libseccomp2 # deve essere almeno 2.42

#docker run -d --name="home-assistant" -e "TZ=Europe/Rome" -v "~/homeassistant:/config" -v "/run/dbus:/run/dbus:ro" --net=host --restart always ghcr.io/home-assistant/home-assistant:stable
