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


# Making .config and Moving config files and background to Pictures
cd $builddir
#mkdir -p /home/$username/.config
#mkdir -p /home/$username/.fonts
#mkdir -p /home/$username/Pictures
#mkdir -p /home/$username/Pictures/backgrounds
#cp -R dotconfig/* /home/$username/.config/
#cp bg.jpg /home/$username/Pictures/backgrounds/
#mv user-dirs.dirs /home/$username/.config
chown -R $username:$username /home/$username

# Install nala
apt install nala -y

# Installing Essential Programs 
nala install feh kitty rofi picom thunar nitrogen x11-xserver-utils unzip wget pipewire wireplumber pavucontrol build-essential zoxide flatpak gnome-software-plugin-flatpak barrier git -y

# Installing Other less important Programs
nala install neofetch flameshot vim  papirus-icon-theme fonts-noto-color-emoji -y

apt -y purge libreoffice*
apt purge iagno lightsoff four-in-a-row gnome-robots pegsolitaire gnome-2048 hitori gnome-klotski gnome-mines gnome-mahjongg gnome-sudoku quadrapassel swell-foop gnome-tetravex gnome-taquin aisleriot gnome-chess five-or-more gnome-nibbles tali gnome-weather gnome-online-accounts gnome-music gnome-sound-recorder gnome-maps gnome-calendar gnome-music gnome-text-editor transmission-common transmission-gtk

apt autoremove

# Enable graphical login and change target from CLI to GUI
systemctl enable lightdm
systemctl set-default graphical.target

# Enable wireplumber audio service

sudo -u $username systemctl --user enable wireplumber.service


# Use nala
bash scripts/usenala

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# https://www.linux.com/training-tutorials/how-install-and-use-flatpak-linux/
# install dir /var/lib/flatpak/app/ # config store ~/.var/app/
# flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
# flatpak install -y flathub com.google.AndroidStudio
flatpak install -y flathub com.brave.Browser 

# Install java-17-amazon-corretto
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
nala update
nala install nvidia-driver firmware-misc-nonfree -y

# Install java-17-amazon-corretto
wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
nala update
nala install java-17-amazon-corretto-jdk -y
