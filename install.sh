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

# Set to false if you do not want an automatic reboot.
REBOOT_AT_END=true

# ------------------------------------------------------------
# Check root
# ------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "You must run this script as root."
    echo
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
# Repair interrupted package configuration
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Checking package state"
echo "============================================================"

dpkg --configure -a || true

# ------------------------------------------------------------
# Remove obsolete Debian 12 third-party repositories
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Cleaning obsolete repositories"
echo "============================================================"

# Old Guideos Debian 12 repository.
# Fastfetch is available directly from Debian 13, so this
# third-party repository is no longer required.

OLD_GUIDEOS_PATTERN="download.opensuse.org/repositories/home:/guideos/Debian_12"

while IFS= read -r file; do
    if [[ -n "$file" && -f "$file" ]]; then
        echo "Removing old Guideos entries from: $file"

        sed -i "\|$OLD_GUIDEOS_PATTERN|d" "$file"
    fi
done < <(
    grep -RIl \
        "$OLD_GUIDEOS_PATTERN" \
        /etc/apt/sources.list \
        /etc/apt/sources.list.d \
        2>/dev/null || true
)

# Remove empty source-list files left behind.
find /etc/apt/sources.list.d \
    -maxdepth 1 \
    -type f \
    -empty \
    -delete \
    2>/dev/null || true

# ------------------------------------------------------------
# Remove obsolete LibreWolf repository configuration
# ------------------------------------------------------------

rm -f \
    /etc/apt/sources.list.d/librewolf.list \
    /etc/apt/sources.list.d/librewolf.sources \
    /etc/apt/keyrings/librewolf.gpg \
    /etc/apt/preferences.d/librewolf.pref \
    /etc/apt/trusted.gpg.d/librewolf.gpg

# ------------------------------------------------------------
# Remove duplicate Debian repository file created by the
# previous installer version.
# ------------------------------------------------------------

rm -f \
    /etc/apt/sources.list.d/debian-trixie-extra.list

# ------------------------------------------------------------
# Debian repository notes
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Checking Debian repositories"
echo "============================================================"

echo "Existing Debian repository configuration will be preserved."
echo "The installer will NOT create duplicate Debian sources."

# Add Trixie backports only if it does not already exist.

if grep -Rqs \
    "trixie-backports" \
    /etc/apt/sources.list \
    /etc/apt/sources.list.d \
    2>/dev/null; then

    echo "Trixie backports repository already configured."

else

    echo "Adding Trixie backports repository..."

    cat > /etc/apt/sources.list.d/debian-trixie-backports.list <<EOF
deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
EOF

fi

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
    ca-certificates \
    curl \
    wget \
    gnupg \
    gpg \
    lsb-release \
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
    python3-pynvim \
    cmatrix \
    diodon \
    vim \
    hollywood \
    fastfetch \
    chromium \
    timeshift

# ------------------------------------------------------------
# Stacer
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing Stacer"
echo "============================================================"

apt-get install -y -t trixie-backports stacer

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
    cp "$BUILDDIR/bg/bg.jpg" \
        "$USER_HOME/Pictures/bg/bg.jpg"
fi

if [[ -d "$BUILDDIR/fonts" ]]; then
    cp -a "$BUILDDIR/fonts/." "$USER_HOME/.fonts/"
fi

if [[ -d "$BUILDDIR/themes" ]]; then
    cp -a "$BUILDDIR/themes/." "$USER_HOME/.themes/"
fi

if [[ -f "$BUILDDIR/user-dirs.dirs" ]]; then
    cp "$BUILDDIR/user-dirs.dirs" \
        "$USER_HOME/.config/user-dirs.dirs"
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

runuser -u "$USERNAME" -- fc-cache -f || true

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

# Remove any previous Syncthing source/key so that the current
# official configuration is always used.

rm -f \
    /etc/apt/sources.list.d/syncthing.list \
    /etc/apt/sources.list.d/syncthing.sources \
    /etc/apt/keyrings/syncthing-archive-keyring.gpg

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

runuser -u "$USERNAME" -- \
    systemctl --user enable syncthing.service \
    || true

# ------------------------------------------------------------
# LibreWolf
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing LibreWolf"
echo "============================================================"

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

    runuser -u "$USERNAME" -- \
        bash -c 'curl -f https://zed.dev/install.sh | sh'

else

    echo "Zed already installed."

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
# Flatpak helper
# ------------------------------------------------------------

install_flatpak()
{
    APP_ID="$1"

    echo
    echo "Installing Flatpak: $APP_ID"

    if flatpak info "$APP_ID" >/dev/null 2>&1; then
        echo "Already installed: $APP_ID"
        return 0
    fi

    if flatpak install -y --system flathub "$APP_ID"; then
        echo "Installed: $APP_ID"
    else
        echo "WARNING: Could not install Flatpak: $APP_ID"
        echo "Continuing with the installer..."
    fi
}

# ------------------------------------------------------------
# Flatpak applications
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installing Flatpak applications"
echo "============================================================"

install_flatpak "com.github.IsmaelMartinez.teams_for_linux"
install_flatpak "io.github.realmazharhussain.GdmSettings"
install_flatpak "com.rtosta.zapzap"
install_flatpak "com.mastermindzh.tidal-hifi"
install_flatpak "hu.irl.cameractrls"
install_flatpak "us.zoom.Zoom"
install_flatpak "org.kde.digikam"
install_flatpak "com.github.PintaProject.Pinta"
install_flatpak "md.obsidian.Obsidian"
install_flatpak "org.bleachbit.BleachBit"
install_flatpak "com.rustdesk.RustDesk"
install_flatpak "com.simplenote.Simplenote"

# LibreWolf is intentionally NOT installed as a Flatpak.
# It is installed above using the official LibreWolf Debian
# repository through extrepo.

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
            "$BUILDDIR/$EXTENSION" \
            || true

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
        gnome-extensions enable "$EXTENSION" \
        || true
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
    false \
    || true

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

    runuser -u "$USERNAME" -- \
        xdg-user-dirs-update \
        || true

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
# Final package update
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Final package update"
echo "============================================================"

apt-get update

apt-get full-upgrade -y

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
# NVIDIA notice
# ------------------------------------------------------------

echo
echo "============================================================"
echo " NVIDIA"
echo "============================================================"

echo "NVIDIA installation/configuration was intentionally skipped."
echo "The installer does not install, remove, or modify NVIDIA drivers."
echo "NVIDIA can be configured manually after the base system is complete."

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
echo "NVIDIA   : untouched"
echo

if [[ "$REBOOT_AT_END" == "true" ]]; then

    echo "The system will reboot in 10 seconds."
    echo "Press Ctrl+C to cancel."
    echo

    sleep 10

    systemctl reboot

else

    echo "Automatic reboot is disabled."

fi
