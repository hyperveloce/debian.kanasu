#!/bin/bash

Check if Script is Run as Root
if [[ $EUID -ne 0 ]]; then
 echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
 exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

##Move home directory
#  #lsblk - find drive to mount
#sudo mkdir -p /mnt/home
#sudo mount /dev/sdb2 /mnt/home
#sudo df -Th
#sudo cp -aR /home/* /mnt/home
#ls -larth /mnt/home/kanasu


# System updates
sudo apt -y update
sudo apt -y upgrade
sudo apt -y dist-upgrade



# Making .config and Moving config files and background to Pictures
cd $builddir
mkdir -p /home/$username/.config
mkdir -p /home/$username/.fonts
mkdir -p /home/$username/Pictures
mkdir -p /home/$username/Pictures/backgrounds
cp -R dotconfig/* /home/$username/.config/
cp bg.jpg /home/$username/Pictures/backgrounds/
mv user-dirs.dirs /home/$username/.config
chown -R $username:$username /home/$username

# ------------------------------------------------- #
# ----- INSTALL Debian APT AVAILABLE SOFTWARE ----- #
# ------------------------------------------------- #

# # Install nala
# apt install nala -y

# Installing Essential Programs
apt install feh kitty rofi thunar nitrogen x11-xserver-utils unzip wget pipewire wireplumber pavucontrol build-essential zoxide flatpak gnome-software-plugin-flatpak barrier git remmina synaptic gnome-tweaks gnome-shell-extension-manager network-manager network-manager-gnome network-manager-openvpn network-manager-openvpn-gnome
 -y

# Installing Other less important Programs
apt install neofetch flameshot neovim vim papirus-icon-theme fonts-noto-color-emoji -y

# # Packages needed for window manager installation
# sudo apt install -y picom rofi dunst libnotify-bin unzip wmctrl xdotool

# apt -y purge libreoffice*
# apt purge iagno lightsoff four-in-a-row gnome-robots pegsolitaire gnome-2048 hitori gnome-klotski gnome-mines gnome-mahjongg gnome-sudoku quadrapassel swell-foop gnome-tetravex gnome-taquin aisleriot gnome-chess five-or-more gnome-nibbles tali gnome-weather gnome-online-accounts gnome-music gnome-sound-recorder gnome-maps gnome-calendar gnome-music gnome-text-editor transmission-common transmission-gtk firefox-esr

# Download Nordic Theme
cd /usr/share/themes/
git clone https://github.com/EliverLara/Nordic.git

# Installing fonts
cd $builddir
apt install fonts-font-awesome -y
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip FiraCode.zip -d /home/$username/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip
unzip Meslo.zip -d /home/$username/.fonts
mv dotfonts/fontawesome/otfs/*.otf /home/$username/.fonts/
chown $username:$username /home/$username/.fonts/*

# Reloading Font
fc-cache -vf
# Removing zip Files
rm ./FiraCode.zip ./Meslo.zip

# Install Nordzy cursor
git clone https://github.com/alvatip/Nordzy-cursors
cd Nordzy-cursors
./install.sh
cd $builddir
rm -rf Nordzy-cursors

# Enable wireplumber audio service
sudo -u $username systemctl --user enable wireplumber.service
apt autoremove

# # Use nala
# bash scripts/usenala

# -------------------------------------- #
# ----- FLATPAK ----- #
# -------------------------------------- #

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# install dir /var/lib/flatpak/app/ # config store ~/.var/app/
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub io.github.mimbrero.WhatsAppDesktop
flatpak install -y flathub io.atom.Atom
flatpak install -y flathub com.mastermindzh.tidal-hifi
# flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community
# flatpak install -y flathub com.google.AndroidStudio


# Install NVIDIA
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
apt update
apt install nvidia-driver firmware-misc-nonfree -y

# Install java-17-amazon-corretto -- https://linuxconfig.org/how-to-locate-and-set-java-home-directory-on-linux
wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
apt update
apt install java-17-amazon-corretto-jdk -y


sudo apt autoremove

printf "\e[1;32mYou can now reboot! Thanks you.\e[0m\n"


### Reference --
### https://github.com/ChrisTitusTech/Debian-titus
