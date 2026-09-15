#!/bin/bash

# ============================================================
# Debian 13 (Trixie) - HyperVeloce / Kanasu Setup
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

HOSTNAME="hyperveloce"
TIMEZONE="Australia/Melbourne"
USERNAME="kanasu"

# ------------------------------------------------------------
# Check root
# ------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "You must run this script as root."
    echo "Example:"
    echo "  sudo ./install.sh"
    exit 1
fi

# ------------------------------------------------------------
# Check Debian version
# ------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    echo "Cannot determine operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID:-}" != "debian" ]]; then
    echo "This script is intended for Debian."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

if [[ "${VERSION_ID:-}" != "13" ]]; then
    echo "This script is intended for Debian 13 (Trixie)."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

echo
echo "============================================================"
echo " Debian 13 (Trixie) setup"
echo "============================================================"
echo

# ------------------------------------------------------------
# Determine build directory
# ------------------------------------------------------------

BUILDDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------
# Determine desktop user
# ------------------------------------------------------------

if id "$USERNAME" >/dev/null 2>&1; then
    echo "User $USERNAME already exists."
else
    echo "Creating user $USERNAME..."
    adduser "$USERNAME"
fi

usermod -aG sudo "$USERNAME"

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

echo "Username : $USERNAME"
echo "Home     : $USER_HOME"
echo "Build dir: $BUILDDIR"

# ------------------------------------------------------------
# System update
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Updating Debian"
echo "============================================================"

apt-get update
apt-get full-upgrade -y

# ------------------------------------------------------------
# Basic system configuration
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Configuring system"
echo "============================================================"

hostnamectl set-hostname "$HOSTNAME"
timedatectl set-timezone "$TIMEZONE"

# ------------------------------------------------------------
# Install basic packages
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing Debian packages"
echo "============================================================"

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    gpg \
    lsb-release \
    software-properties-common \
    extrepo \
    nala \
    sudo \
    ufw \
    fail2ban \
    git \
    unzip \
    build-essential \
    x11-xserver-utils \
    network-manager \
    network-manager-gnome \
    network-manager-openvpn \
    network-manager-openvpn-gnome \
    btop \
    picom \
    dupeguru \
    qjackctl \
    xarchiver \
    preload \
    zoxide \
    flatpak \
    gnome-software \
    gnome-software-plugin-flatpak \
    synaptic \
    gnome-tweaks \
    gnome-shell-extension-manager \
    gnome-shell-extensions \
    gnome-shell-extension-prefs \
    gnome-shell-extension-user-theme \
    gnome-shell-extension-weather \
    gnome-power-manager \
    feh \
    geeqie \
    shotwell \
    darktable \
    papirus-icon-theme \
    fonts-noto-color-emoji \
    fonts-font-awesome \
    kitty \
    neovim \
    python3-neovim \
    cmatrix \
    diodon \
    vim \
    hollywood \
    fastfetch \
    chromium \
    barrier \
    stacer \
    timeshift

# ------------------------------------------------------------
# Firewall
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Configuring UFW"
echo "============================================================"

ufw default deny incoming
ufw default allow outgoing

# SSH
ufw allow 22/tcp

ufw --force enable

# ------------------------------------------------------------
# Fail2ban
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Configuring Fail2ban"
echo "============================================================"

systemctl enable fail2ban
systemctl restart fail2ban

# ------------------------------------------------------------
# Create user directories
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Creating user directories"
echo "============================================================"

mkdir -p "$USER_HOME/.config"
mkdir -p "$USER_HOME/.fonts"
mkdir -p "$USER_HOME/.themes"
mkdir -p "$USER_HOME/Pictures"
mkdir -p "$USER_HOME/Pictures/bg"

# ------------------------------------------------------------
# Copy configuration files
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing configuration files"
echo "============================================================"

if [[ -d "$BUILDDIR/dotconfig" ]]; then
    cp -a "$BUILDDIR/dotconfig/." "$USER_HOME/.config/"
fi

if [[ -f "$BUILDDIR/bg/bg.jpg" ]]; then
    cp "$BUILDDIR/bg/bg.jpg" "$USER_HOME/Pictures/bg/bg.jpg"
fi

if [[ -d "$BUILDDIR/fonts" ]]; then
    cp -a "$BUILDDIR/fonts/." "$USER_HOME/.fonts/"
fi

if [[ -d "$BUILDDIR/themes" ]]; then
    cp -a "$BUILDDIR/themes/." "$USER_HOME/.themes/"
fi

if [[ -f "$BUILDDIR/user-dirs.dirs" ]]; then
    cp "$BUILDDIR/user-dirs.dirs" "$USER_HOME/.config/user-dirs.dirs"
fi

# ------------------------------------------------------------
# Fix ownership
# ------------------------------------------------------------

chown -R "$USERNAME:$USERNAME" "$USER_HOME"

# ------------------------------------------------------------
# Refresh fonts
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Updating fonts"
echo "============================================================"

runuser -u "$USERNAME" -- fc-cache -f

# ------------------------------------------------------------
# Remove unwanted Debian/GNOME packages
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Removing unwanted packages"
echo "============================================================"

apt-get purge -y \
    'libreoffice*' \
    firefox-esr \
    gnome-contacts \
    rhythmbox \
    cheese \
    iagno \
    lightsoff \
    four-in-a-row \
    gnome-robots \
    pegsolitaire \
    gnome-2048 \
    hitori \
    gnome-klotski \
    gnome-mines \
    gnome-mahjongg \
    gnome-sudoku \
    quadrapassel \
    swell-foop \
    gnome-tetravex \
    gnome-taquin \
    aisleriot \
    gnome-chess \
    five-or-more \
    gnome-nibbles \
    tali \
    gnome-weather \
    gnome-online-accounts \
    gnome-music \
    gnome-sound-recorder \
    gnome-maps \
    gnome-calendar \
    gnome-text-editor \
    transmission-common \
    transmission-gtk \
    evolution \
    2>/dev/null || true

apt-get autoremove -y

# ------------------------------------------------------------
# Syncthing repository
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing Syncthing"
echo "============================================================"

mkdir -p /etc/apt/keyrings

curl -L \
    -o /etc/apt/keyrings/syncthing-archive-keyring.gpg \
    https://syncthing.net/release-key.gpg

cat > /etc/apt/sources.list.d/syncthing.list <<EOF
deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2
EOF

apt-get update
apt-get install -y syncthing

# ------------------------------------------------------------
# Enable Syncthing for user
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Configuring Syncthing"
echo "============================================================"

loginctl enable-linger "$USERNAME" || true

runuser -u "$USERNAME" -- systemctl --user enable syncthing.service || true

# ------------------------------------------------------------
# LibreWolf
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing LibreWolf"
echo "============================================================"

# Remove old LibreWolf repository configuration from Debian 12.
rm -f \
    /etc/apt/sources.list.d/librewolf.list \
    /etc/apt/sources.list.d/librewolf.sources \
    /etc/apt/keyrings/librewolf.gpg \
    /etc/apt/preferences.d/librewolf.pref \
    /etc/apt/trusted.gpg.d/librewolf.gpg

apt-get update

if ! command -v extrepo >/dev/null 2>&1; then
    apt-get install -y extrepo
fi

extrepo enable librewolf

apt-get update
apt-get install -y librewolf

# ------------------------------------------------------------
# Brave Browser
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing Brave Browser"
echo "============================================================"

mkdir -p /usr/share/keyrings

curl -fsSLo \
    /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

cat > /etc/apt/sources.list.d/brave-browser-release.list <<EOF
deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main
EOF

apt-get update
apt-get install -y brave-browser

# ------------------------------------------------------------
# Zed editor
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing Zed"
echo "============================================================"

if [[ ! -x "$USER_HOME/.local/bin/zed" ]]; then
    runuser -u "$USERNAME" -- bash -c \
        'curl -f https://zed.dev/install.sh | sh'
fi

# ------------------------------------------------------------
# Flatpak / Flathub
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Configuring Flatpak"
echo "============================================================"

flatpak remote-add \
    --if-not-exists \
    flathub \
    https://flathub.org/repo/flathub.flatpakrepo

# ------------------------------------------------------------
# Flatpak applications
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing Flatpak applications"
echo "============================================================"

flatpak install -y --system flathub \
    com.github.IsmaelMartinez.teams_for_linux

flatpak install -y --system flathub \
    io.github.realmazharhussain.GdmSettings

flatpak install -y --system flathub \
    com.rtosta.zapzap

flatpak install -y --system flathub \
    com.mastermindzh.tidal-hifi

flatpak install -y --system flathub \
    hu.irl.cameractrls

flatpak install -y --system flathub \
    us.zoom.Zoom

flatpak install -y --system flathub \
    org.kde.digikam

flatpak install -y --system flathub \
    com.github.PintaProject.Pinta

flatpak install -y --system flathub \
    md.obsidian.Obsidian

flatpak install -y --system flathub \
    io.gitlab.librewolf-community

flatpak install -y --system flathub \
    org.bleachbit.BleachBit

flatpak install -y --system flathub \
    com.rustdesk.RustDesk

flatpak install -y --system flathub \
    com.simplenote.Simplenote

# ------------------------------------------------------------
# GNOME extension installation
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing GNOME extensions"
echo "============================================================"

install_extension()
{
    EXTENSION="$1"

    if [[ -f "$BUILDDIR/$EXTENSION" ]]; then
        echo "Installing $EXTENSION"

        runuser -u "$USERNAME" -- \
            gnome-extensions install \
            --force \
            "$BUILDDIR/$EXTENSION" || true
    else
        echo "Extension not found: $EXTENSION"
    fi
}

install_extension "customreboot@nova1545.zip"
install_extension "openweather-extension@jenslody.de.zip"
install_extension "openbar@neuromorph.zip"
install_extension "Vitals@CoreCoding.com.zip"
install_extension "blur-my-shell@aunetx.zip"
install_extension "unblank@sun.wxg@gmail.com.zip"

# ------------------------------------------------------------
# Enable GNOME extensions
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Enabling GNOME extensions"
echo "============================================================"

enable_extension()
{
    EXTENSION="$1"

    runuser -u "$USERNAME" -- \
        gnome-extensions enable "$EXTENSION" || true
}

enable_extension "customreboot@nova1545"
enable_extension "openweather-extension@jenslody.de"
enable_extension "openbar@neuromorph"
enable_extension "Vitals@CoreCoding.com"
enable_extension "blur-my-shell@aunetx"
enable_extension "unblank@sun.wxg@gmail.com"
enable_extension "user-theme@gnome-shell-extensions.gcampax.github.com"

# ------------------------------------------------------------
# GNOME configuration
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Configuring GNOME"
echo "============================================================"

if [[ -f "$BUILDDIR/gnome/gnome-settings.ini" ]]; then

    runuser -u "$USERNAME" -- \
        bash -c \
        "dconf load / < '$BUILDDIR/gnome/gnome-settings.ini'" \
        || true

fi

if [[ -f "$USER_HOME/Pictures/bg/bg.jpg" ]]; then

    runuser -u "$USERNAME" -- \
        gsettings set \
        org.gnome.desktop.background \
        picture-uri-dark \
        "file://$USER_HOME/Pictures/bg/bg.jpg" \
        || true

    runuser -u "$USERNAME" -- \
        gsettings set \
        org.gnome.desktop.background \
        picture-uri \
        "file://$USER_HOME/Pictures/bg/bg.jpg" \
        || true

fi

# ------------------------------------------------------------
# GNOME favourites
# ------------------------------------------------------------

runuser -u "$USERNAME" -- \
    gsettings set \
    org.gnome.shell \
    favorite-apps \
    "[
        'thunar.desktop',
        'kitty.desktop',
        'chromium.desktop',
        'brave-browser.desktop',
        'io.atom.Atom.desktop',
        'com.mastermindzh.tidal-hifi.desktop',
        'io.github.mimbrero.WhatsAppDesktop.desktop'
    ]" || true

# ------------------------------------------------------------
# Disable GNOME animations
# ------------------------------------------------------------

runuser -u "$USERNAME" -- \
    gsettings set \
    org.gnome.desktop.interface \
    enable-animations \
    false || true

# ------------------------------------------------------------
# WirePlumber
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Configuring WirePlumber"
echo "============================================================"

runuser -u "$USERNAME" -- \
    systemctl --user enable wireplumber.service \
    || true

# ------------------------------------------------------------
# User directory configuration
# ------------------------------------------------------------

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    runuser -u "$USERNAME" -- xdg-user-dirs-update || true
fi

# ------------------------------------------------------------
# Custom scripts
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Running custom scripts"
echo "============================================================"

if [[ -f "$BUILDDIR/scripts/setup.sh" ]]; then
    chmod +x "$BUILDDIR/scripts/setup.sh"
    bash "$BUILDDIR/scripts/setup.sh"
fi

if [[ -f "$BUILDDIR/scripts/usenala" ]]; then
    chmod +x "$BUILDDIR/scripts/usenala"
    bash "$BUILDDIR/scripts/usenala"
fi

# ------------------------------------------------------------
# Final cleanup
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Cleaning up"
echo "============================================================"

apt-get autoremove -y
apt-get autoclean -y

# ------------------------------------------------------------
# Final permissions
# ------------------------------------------------------------

chown -R "$USERNAME:$USERNAME" "$USER_HOME"

# ------------------------------------------------------------
# Finished
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Debian 13 setup complete"
echo "============================================================"
echo
echo "Hostname : $HOSTNAME"
echo "User     : $USERNAME"
echo "Debian   : 13 (Trixie)"
echo
echo "The system will reboot in 10 seconds."
echo "Press Ctrl+C to cancel."
echo

sleep 10

systemctl reboot
