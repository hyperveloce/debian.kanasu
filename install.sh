#!/bin/bash

Check if Script is Run as Root
if [[ $EUID -ne 0 ]]; then
 echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
 exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

#sudo mkdir -p /mnt/home
#sudo mount /dev/sda2 /mnt/home
#sudo df -Th
#sudo cp -aR /home/* /mnt/home
#sudo umount /dev/sda2
#sudo mount /dev/sda2 /home
#sudo blkid /dev/sda2
#sudo vim /etc/fstab
#UUID=7ddfdaed-95fe-4f25-9e64-37cb0b541404    /home    ext4    defaults   0  2
#echo "UUID=7ddfdaed-95fe-4f25-9e64-37cb0b541404    /home    ext4    defaults   0  2" | sudo tee /etc/fstab

#sudo blkid -f
# echo "UUID=CC0889CD0889B74C    /mnt/m.2    ntfs    defaults   0  2" | sudo tee /etc/fstab
# echo "UUID=CE7EA4717EA4544D    /mnt/w.System    ntfs    defaults   0  2" | sudo tee /etc/fstab
# echo "UUID=543022F1761BF872    /mnt/kanasu.space    ntfs    defaults   0  2" | sudo tee /etc/fstab

# System updates
sudo apt update && sudo apt upgrade -y

# System setup
sudo hostnamectl set-hostname hyperveloce
sudo timedatectl set-timezone Australia/Melbourne

# user setup
sudo adduser kanasu
sudo usermod -aG sudo kanasu

# firewall setup
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp  # or the port you set for SSH
sudo ufw enable

# brute force protection
sudo apt install fail2ban
sudo systemctl enable fail2ban

# Making .config and Moving config files and background to Pictures
cd $builddir
mkdir -p /home/$username/.config
mkdir -p /home/$username/.fonts
mkdir -p /home/$username/.themes
mkdir -p /home/$username/Pictures
mkdir -p /home/$username/Pictures/bg
cp -R dotconfig/* /home/$username/.config/
cp bg/bg.jpg /home/$username/Pictures/bg/
cp themes /home/$username/.themes
mv user-dirs.dirs /home/$username/.config
chown -R $username:$username /home/$username

# ------------------------------------------------- #
# ----- INSTALL Debian APT AVAILABLE SOFTWARE ----- #
# ------------------------------------------------- #

# # Install nala
apt install nala -y

sudo apt install -y \

# 🛠️ System Tools
stacer \
timeshift \
barrier \
btop \
picom \
dupeguru \
qjackctl \
xarchiver \
curl \
x11-xserver-utils \
unzip \
wget \
preload \
build-essential \
zoxide \
flatpak \
gnome-software-plugin-flatpak \
synaptic \
gnome-tweaks \
gnome-shell-extension-manager \
gnome-power-manager \

# 🌐 Networking & Remote Access
network-manager \
network-manager-gnome \
network-manager-openvpn \
network-manager-openvpn-gnome \

# 🌍 Web Browsers
brave-browser \
librewolf \
chromium \

# 🖼️ Image & Media Utilities
feh \
geeqie \
shotwell \
org.darktable.darktable \
papirus-icon-theme \
fonts-noto-color-emoji \

# 🧰 Developer & Power User Tools
kitty \
neovim \
cmatrix \
diodon \
vim \

# 🎭 Miscellaneous & Fun
hollywood \
fastfetch

# # Packages needed for window manager installation
# sudo apt install -y picom nitrogen rofi dunst libnotify-bin wmctrl xdotool

# dpkg --list | grep <package>

apt purge libreoffice* -y
apt purge firefox-esr gnome-contacts rhythmbox cheese iagno lightsoff four-in-a-row gnome-robots pegsolitaire gnome-2048 hitori gnome-klotski gnome-mines gnome-mahjongg gnome-sudoku quadrapassel swell-foop gnome-tetravex gnome-taquin aisleriot gnome-chess five-or-more gnome-nibbles tali gnome-weather gnome-online-accounts gnome-music gnome-sound-recorder gnome-maps gnome-calendar gnome-music gnome-text-editor transmission-common transmission-gtk firefox-esr evolution -y


# Installing fonts
cd $builddir
apt install fonts-font-awesome -y
cp -R fonts/* /home/$username/.fonts/
chown $username:$username /home/$username/.fonts/*
# Reloading Font
fc-cache -vf


# Enable wireplumber audio service
sudo -u $username systemctl --user enable wireplumber.service
apt autoremove

# Beautiful bash
bash scripts/setup.sh

# Use nala
bash scripts/usenala

# Download Nordic Theme
#cd /usr/share/themes/
#git clone https://github.com/EliverLara/Nordic.git

# Install Nordzy cursor
#git clone https://github.com/alvatip/Nordzy-cursors
#cd Nordzy-cursors
#./install.sh
#cd $builddir
#rm -rf Nordzy-cursors

# Add Syncthing repo key
curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
# Add Syncthing repo
echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
# Update and install
sudo apt update
sudo apt install syncthing -y

# ----- FLATPAK ----- #

# Add Flathub repo if not already added
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Flatpak apps system-wide from Flathub
flatpak install -y --system flathub com.github.IsmaelMartinez.teams_for_linux
flatpak install -y --system flathub io.github.realmazharhussain.GdmSettings
flatpak install -y --system flathub flathub com.rtosta.zapzap
flatpak install -y --system flathub com.mastermindzh.tidal-hifi
flatpak install -y --system flathub hu.irl.cameractrls
flatpak install -y --system flathub us.zoom.Zoom
flatpak install -y --system flathub org.kde.digikam
flatpak install -y --system flathub com.github.PintaProject.Pinta
flatpak install -y --system flathub md.obsidian.Obsidian
flatpak install -y --system flathub io.gitlab.librewolf-community
flatpak install -y --system flathub bleachbit
flatpak install -y --system flathub com.rustdesk.RustDesk

# Install Zed
curl -f https://zed.dev/install.sh | sh
# neovim
sudo apt-get install neovim
sudo apt-get install python3-neovim

# Install Brave
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
apt update
apt install brave-browser

# Install librewolf
wget -O- https://deb.librewolf.net/keyring.gpg | sudo tee /usr/share/keyrings/librewolf-keyring.gpg
sudo apt update && sudo apt install librewolf -y

# fastfetch
echo 'deb http://download.opensuse.org/repositories/home:/guideos/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:guideos.list
curl -fsSL https://download.opensuse.org/repositories/home:guideos/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_guideos.gpg > /dev/null
apt update
apt install fastfetch

# ----- Set gnome-extensions ----- #
gnome-extensions install --force customreboot@nova1545.zip && gnome-extensions enable customreboot@nova1545
gnome-extensions install --force openweather-extension@jenslody.de.zip && gnome-extensions enable openweather-extension@jenslody.de
gnome-extensions install --force openbar@neuromorph.zip && gnome-extensions enable openbar@neuromorph
gnome-extensions install --force Vitals@CoreCoding.com.zip && gnome-extensions enable Vitals@CoreCoding.com
gnome-extensions install --force blur-my-shell@aunetx.zip && gnome-extensions enable blur-my-shell@aunetx
gnome-extensions install --force unblank@sun.wxg@gmail.com.zip && gnome-extensions enable unblank@sun.wxg@gmail.com

gnome-extensions enable customreboot@nova1545 || true
gnome-extensions enable openweather-extension@jenslody.de || true
gnome-extensions enable openbar@neuromorph || true
gnome-extensions enable Vitals@CoreCoding.com || true
gnome-extensions enable blur-my-shell@aunetx || true
gnome-extensions enable unblank@sun.wxg@gmail.com || true
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true

# ----- Setup GNOME Desktop ----- #
# Set GNOME tweaks settings
cp bg/bg.jpg /home/kanasu/Pictures/bg/
gsettings set org.gnome.desktop.background picture-uri-dark "/home/kanasu/Pictures/bg/bg.jpg"
dconf load / < gnome/gnome-settings.ini
gsettings get org.gnome.shell favorite-apps
gsettings set org.gnome.shell favorite-apps "['thunar.desktop', 'kitty.desktop', 'chromium.desktop', 'brave-browser.desktop', 'io.atom.Atom.desktop', 'com.mastermindzh.tidal-hifi.desktop', 'io.github.mimbrero.WhatsAppDesktop.desktop']"
gsettings set org.gnome.desktop.interface enable-animations false

printf "\e[1;32mYour system is ready and will go for reboot! Thanks you.\e[0m\n"

systemctl reboot
