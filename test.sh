#!/bin/bash

# Check if Script is Run as Root
#if [[ $EUID -ne 0 ]]; then
#  echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
#  exit 1
#fi

#username=$(id -u -n 1000)
#builddir=$(pwd)

##Move home directory
#  #lsblk - find drive to mount
#sudo mkdir -p /mnt/home
#sudo mount /dev/sda2 /mnt/home
#sudo df -Th
#sudo cp -aR /home/* /mnt/home
#ls -larth /mnt/home/kanasu


# Update packages list and update system
apt update
apt upgrade -y
