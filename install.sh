#!/bin/bash

Check if Script is Run as Root
if [[ $EUID -ne 0 ]]; then
 echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
 exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

# ##Move home directory -- lsblk -f
# sudo mkdir /mnt/w.System
# sudo mount /dev/nvme0n1p2 /mnt/w.System
# sudo mkdir /mnt/b.System
# sudo mount /dev/nvme1n1p1 /mnt/b.System
# sudo mkdir /mnt/hyper.space
# sudo mount /dev/sdb2 /mnt/hyper.space
# sudo mkdir /mnt/kanasu.space
# sudo mount /dev/sda3 /mnt/kanasu.space

#sudo mkdir -p /mnt/home
#sudo mount /dev/sdb2 /mnt/home
sudo mount /dev/sda1 /mnt/home
#sudo df -Th
#sudo cp -aR /home/* /mnt/home
#ls -larth /mnt/home/kanasu
#sudo vim /etc/fstab
#UUID=<noted number from above>    /home    ext4    defaults   0  2

# System updates
sudo apt -y update && sudo apt -y upgrade && sudo apt -y dist-upgrade

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
apt install nala -y

# Installing Essential Programs
apt install feh kitty thunar x11-xserver-utils unzip wget pipewire wireplumber pavucontrol build-essential zoxide flatpak gnome-software-plugin-flatpak barrier git remmina synaptic gnome-tweaks gnome-shell-extension-manager network-manager network-manager-gnome network-manager-openvpn network-manager-openvpn-gnome
 -y

# Installing Other less important Programs
apt install neofetch flameshot neovim vim papirus-icon-theme fonts-noto-color-emoji -y

# # Packages needed for window manager installation
# sudo apt install -y picom nitrogen rofi dunst libnotify-bin wmctrl xdotool

# apt purge libreoffice* -y
# apt purge iagno lightsoff four-in-a-row gnome-robots pegsolitaire gnome-2048 hitori gnome-klotski gnome-mines gnome-mahjongg gnome-sudoku quadrapassel swell-foop gnome-tetravex gnome-taquin aisleriot gnome-chess five-or-more gnome-nibbles tali gnome-weather gnome-online-accounts gnome-music gnome-sound-recorder gnome-maps gnome-calendar gnome-music gnome-text-editor transmission-common transmission-gtk firefox-esr

# Download Nordic Theme
#cd /usr/share/themes/
#git clone https://github.com/EliverLara/Nordic.git

# Installing fonts
cd $builddir
apt install fonts-font-awesome -y
cp -R fonts/* /home/$username/.fonts/
chown $username:$username /home/$username/.fonts/*
# Reloading Font
fc-cache -vf

# Install Nordzy cursor
#git clone https://github.com/alvatip/Nordzy-cursors
#cd Nordzy-cursors
#./install.sh
#cd $builddir
#rm -rf Nordzy-cursors

# Enable wireplumber audio service
sudo -u $username systemctl --user enable wireplumber.service
apt autoremove

# Beautiful bash
bash scripts/setup.sh

# Use nala
bash scripts/usenala

# -------------------------------------- #
# ----- FLATPAK ----- #
# -------------------------------------- #

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# install dir /var/lib/flatpak/app/ # config store ~/.var/app/
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
flatpak install -y flathub io.github.realmazharhussain.GdmSettings
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub io.github.mimbrero.WhatsAppDesktop
flatpak install -y flathub io.atom.Atom
flatpak install -y flathub com.mastermindzh.tidal-hifi
# flatpak install -y flathub com.visualstudio.code
# flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community
# flatpak install -y flathub com.google.AndroidStudio


# # Install NVIDIA --> /etc/apt/sources.list
# deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
# apt update
# apt install nvidia-driver firmware-misc-nonfree -y
#
# # Install java-17-amazon-corretto -- https://linuxconfig.org/how-to-locate-and-set-java-home-directory-on-linux
# wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
# echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list
# apt update
# apt install java-17-amazon-corretto-jdk -y

printf "\e[1;32mYour system is ready and will go for reboot! Thanks you.\e[0m\n"

systemctl reboot

### Reference --
### https://github.com/ChrisTitusTech/Debian-titus
#https://www.reddit.com/r/unixporn/comments/18vnz41/bspwm_tokyo_night_minor_changes_since_last_year/

########################################################################################################################
########################################################################################################################

# # Quick Emulator & Virtual Machine Manager
# sudo apt install -y qemu-system virt-manager



# ----- Google Chrome ----- #
# wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# sudo apt install -y ./google-chrome-stable_current_amd64.deb
# rm google-chrome-stable_current_amd64.deb


# ----- Install GNOME extension ----- #
# # Download GNOME extensions
# wget https://extensions.gnome.org/extension-data/dash-to-dockmicxgx.gmail.com.v84.shell-extension.zip
# wget https://extensions.gnome.org/extension-data/apps-menugnome-shell-extensions.gcampax.github.com.v52.shell-extension.zip
#
# # Install GNOME extensions
# gnome-extensions install dash-to-dockmicxgx.gmail.com.v84.shell-extension.zip
# gnome-extensions install apps-menugnome-shell-extensions.gcampax.github.com.v52.shell-extension.zip

# ----- Setup GNOME Desktop ----- #
# # Set GNOME tweaks settings
# gsettings set org.gnome.desktop.wm.preferences button-layout 'icon:minimize,maximize,close'
# gsettings set org.gnome.mutter center-new-windows true
#
# # Use the following to find a GNOME setting
# #   gsettings list-recursively > /tmp/gsettings.before
# #   gsettings list-recursively > /tmp/gsettings.after
# #   diff /tmp/gsettings.before /tmp/gsettings.after | grep '[>|<]'
#
# # Enable extensions
# gnome-extensions enable dash-to-dock@micxgx.gmail.com
# gnome-extensions enable apps-menu@gnome-shell-extensions.gcampax.github.com
# # ----- Set dash-to-dock extension settings ----- #
# SCHEMADIR="/home/$USER/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/"
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock dock-fixed true
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock extend-height true
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock click-action 'minimize-or-previews'
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock animate-show-apps false
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock show-trash true
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock show-mounts false
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'SEGMENTED'
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock unity-backlit-items false
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock running-indicator-dominant-color true
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock custom-theme-customize-running-dots false
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
# gsettings --schemadir $SCHEMADIR set org.gnome.shell.extensions.dash-to-dock background-opacity 0.75
#
# # Use the following to list keys and current values of dash-to-dock extension **** change <user> to the actual users directory name ****
# #   gsettings --schemadir /home/<user>/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/ list-recursively org.gnome.shell.extensions.dash-to-dock
#
# done
#
# # ----- Set favorite-apps ----- #
# # Use the following the get your favorite apps list
# #   gsettings get org.gnome.shell favorite-apps
# gsettings set org.gnome.shell favorite-apps "['org.gnome.Terminal.desktop', 'org.gnome.gedit.desktop', 'github-desktop.desktop', 'cmake-gui.desktop', 'org.gnome.Nautilus.desktop', 'makemkv.desktop', 'virtualbox.desktop', 'org.gnome.Software.desktop', 'gufw.desktop']"
#

### Gaming emulator
# sudo apt install -y fceux
# sudo apt install -y
