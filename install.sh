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

# NVIDIA is intentionally NOT managed by this installer.
# NVIDIA installation/update will be handled manually.
INSTALL_NVIDIA="false"

# ------------------------------------------------------------
# Colours
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

print_section()
{
    echo
    echo "============================================================"
    echo " $1"
    echo "============================================================"
    echo
}

info()
{
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning()
{
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error()
{
    echo -e "${RED}[ERROR]${NC} $1"
}

# ------------------------------------------------------------
# Check root
# ------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    error "You must run this script as root."
    echo
    echo "Run:"
    echo "  sudo ./install.sh"
    echo
    exit 1
fi

# ------------------------------------------------------------
# Check operating system
# ------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    error "Cannot determine operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID:-}" != "debian" ]]; then
    error "This script is intended for Debian."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

if [[ "${VERSION_ID:-}" != "13" ]]; then
    error "This script is intended for Debian 13 (Trixie)."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

print_section "Debian 13 (Trixie) setup"

info "Detected: ${PRETTY_NAME}"
info "NVIDIA installation/update: DISABLED"

# ------------------------------------------------------------
# Determine build directory
# ------------------------------------------------------------

BUILDDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "Build directory: $BUILDDIR"

# ------------------------------------------------------------
# Determine desktop user
# ------------------------------------------------------------

if id "$USERNAME" >/dev/null 2>&1; then

    info "User $USERNAME already exists."

else

    info "Creating user $USERNAME..."

    adduser "$USERNAME"

fi

usermod -aG sudo "$USERNAME"

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

info "Username : $USERNAME"
info "Home     : $USER_HOME"

# ------------------------------------------------------------
# Clean old Debian 12 repositories
# ------------------------------------------------------------

print_section "Cleaning old Debian 12 repositories"

# Old Guideos repository used by the previous installer.
# Debian 13 now provides fastfetch directly, so this repository
# is no longer required.

OLD_GUIDEOS_PATTERN="download.opensuse.org/repositories/home:/guideos/Debian_12"

while IFS= read -r file; do

    if [[ -n "$file" && -f "$file" ]]; then

        info "Removing old Guideos repository from:"
        echo "  $file"

        sed -i "\|$OLD_GUIDEOS_PATTERN|d" "$file"

    fi

done < <(
    grep -RIl "$OLD_GUIDEOS_PATTERN" \
        /etc/apt/sources.list \
        /etc/apt/sources.list.d \
        2>/dev/null || true
)

# Remove empty old repository files where appropriate.

find /etc/apt/sources.list.d \
    -maxdepth 1 \
    -type f \
    -empty \
    -delete \
    2>/dev/null || true

# ------------------------------------------------------------
# Clean old LibreWolf repository
# ------------------------------------------------------------

rm -f \
    /etc/apt/sources.list.d/librewolf.list \
    /etc/apt/sources.list.d/librewolf.sources \
    /etc/apt/keyrings/librewolf.gpg \
    /etc/apt/preferences.d/librewolf.pref \
    /etc/apt/trusted.gpg.d/librewolf.gpg

# ------------------------------------------------------------
# Remove old Syncthing configuration
# ------------------------------------------------------------

rm -f \
    /etc/apt/sources.list.d/syncthing.list \
    /etc/apt/keyrings/syncthing-archive-keyring.gpg

# ------------------------------------------------------------
# Remove old NVIDIA repository configuration
# ------------------------------------------------------------

# The installer does NOT install NVIDIA.
#
# We only remove known NVIDIA repository files that may have
# been created by previous versions of the installer.
#
# Existing NVIDIA driver packages are NOT removed.

rm -f \
    /etc/apt/sources.list.d/nvidia.list \
    /etc/apt/sources.list.d/nvidia-d12.list \
    /etc/apt/sources.list.d/cuda.list

# ------------------------------------------------------------
# Configure Debian repositories
# ------------------------------------------------------------

print_section "Configuring Debian repositories"

# Debian 13 needs these components for non-free firmware,
# optional software and future manual NVIDIA management.

cat > /etc/apt/sources.list.d/debian-trixie-extra.list <<EOF
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
EOF

# ------------------------------------------------------------
# Initial package update
# ------------------------------------------------------------

print_section "Updating Debian"

apt-get update

apt-get full-upgrade -y

# ------------------------------------------------------------
# Basic system configuration
# ------------------------------------------------------------

print_section "Configuring system"

hostnamectl set-hostname "$HOSTNAME"

timedatectl set-timezone "$TIMEZONE"

# ------------------------------------------------------------
# Install basic packages
# ------------------------------------------------------------

print_section "Installing Debian packages"

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
    timeshift

# Stacer is currently in Trixie Backports.

apt-get install -y -t trixie-backports stacer

# ------------------------------------------------------------
# Firewall
# ------------------------------------------------------------

print_section "Configuring UFW"

ufw default deny incoming
ufw default allow outgoing

# SSH

ufw allow 22/tcp

ufw --force enable

# ------------------------------------------------------------
# Fail2ban
# ------------------------------------------------------------

print_section "Configuring Fail2ban"

systemctl enable fail2ban
systemctl restart fail2ban

# ------------------------------------------------------------
# Create user directories
# ------------------------------------------------------------

print_section "Creating user directories"

mkdir -p "$USER_HOME/.config"
mkdir -p "$USER_HOME/.fonts"
mkdir -p "$USER_HOME/.themes"
mkdir -p "$USER_HOME/Pictures"
mkdir -p "$USER_HOME/Pictures/bg"

# ------------------------------------------------------------
# Copy configuration files
# ------------------------------------------------------------

print_section "Installing configuration files"

if [[ -d "$BUILDDIR/dotconfig" ]]; then

    info "Copying dotconfig..."

    cp -a "$BUILDDIR/dotconfig/." \
        "$USER_HOME/.config/"

fi

if [[ -f "$BUILDDIR/bg/bg.jpg" ]]; then

    info "Copying wallpaper..."

    cp "$BUILDDIR/bg/bg.jpg" \
        "$USER_HOME/Pictures/bg/bg.jpg"

fi

if [[ -d "$BUILDDIR/fonts" ]]; then

    info "Copying fonts..."

    cp -a "$BUILDDIR/fonts/." \
        "$USER_HOME/.fonts/"

fi

if [[ -d "$BUILDDIR/themes" ]]; then

    info "Copying themes..."

    cp -a "$BUILDDIR/themes/." \
        "$USER_HOME/.themes/"

fi

if [[ -f "$BUILDDIR/user-dirs.dirs" ]]; then

    info "Copying user directories configuration..."

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

print_section "Updating fonts"

runuser -u "$USERNAME" -- fc-cache -f

# ------------------------------------------------------------
# Remove unwanted Debian / GNOME packages
# ------------------------------------------------------------

print_section "Removing unwanted packages"

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

print_section "Installing Syncthing"

mkdir -p /etc/apt/keyrings

curl -L \
    -o /etc/apt/keyrings/syncthing-archive-keyring.gpg \
    https://syncthing.net/release-key.gpg

chmod 644 \
    /etc/apt/keyrings/syncthing-archive-keyring.gpg

cat > /etc/apt/sources.list.d/syncthing.list <<EOF
deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2
EOF

apt-get update

apt-get install -y syncthing

# ------------------------------------------------------------
# Enable Syncthing for user
# ------------------------------------------------------------

print_section "Configuring Syncthing"

loginctl enable-linger "$USERNAME" || true

runuser -u "$USERNAME" -- \
    systemctl --user enable syncthing.service \
    || true

# ------------------------------------------------------------
# LibreWolf
# ------------------------------------------------------------

print_section "Installing LibreWolf"

# LibreWolf moved away from the old deb.librewolf.net repository.
# extrepo is now the recommended Debian installation method.

extrepo disable librewolf 2>/dev/null || true

rm -f \
    /etc/apt/sources.list.d/librewolf.list \
    /etc/apt/sources.list.d/librewolf.sources \
    /etc/apt/keyrings/librewolf.gpg \
    /etc/apt/preferences.d/librewolf.pref \
    /etc/apt/trusted.gpg.d/librewolf.gpg

apt-get update

apt-get install -y extrepo

extrepo enable librewolf

apt-get update

apt-get install -y librewolf

# ------------------------------------------------------------
# Brave Browser
# ------------------------------------------------------------

print_section "Installing Brave Browser"

mkdir -p /usr/share/keyrings

curl -fsSLo \
    /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

chmod 644 \
    /usr/share/keyrings/brave-browser-archive-keyring.gpg

cat > /etc/apt/sources.list.d/brave-browser-release.list <<EOF
deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main
EOF

apt-get update

apt-get install -y brave-browser

# ------------------------------------------------------------
# Zed editor
# ------------------------------------------------------------

print_section "Installing Zed"

if [[ ! -x "$USER_HOME/.local/bin/zed" ]]; then

    runuser -u "$USERNAME" -- \
        bash -c 'curl -f https://zed.dev/install.sh | sh'

else

    info "Zed is already installed."

fi

# ------------------------------------------------------------
# Flatpak / Flathub
# ------------------------------------------------------------

print_section "Configuring Flatpak"

flatpak remote-add \
    --if-not-exists \
    flathub \
    https://flathub.org/repo/flathub.flatpakrepo

# ------------------------------------------------------------
# Flatpak applications
# ------------------------------------------------------------

print_section "Installing Flatpak applications"

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

print_section "Installing GNOME extensions"

install_extension()
{
    EXTENSION="$1"

    if [[ -f "$BUILDDIR/$EXTENSION" ]]; then

        info "Installing $EXTENSION"

        runuser -u "$USERNAME" -- \
            gnome-extensions install \
            --force \
            "$BUILDDIR/$EXTENSION" \
            || true

    else

        warning "Extension not found: $EXTENSION"

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

print_section "Enabling GNOME extensions"

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

print_section "Configuring GNOME"

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
    ]" \
    || true

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

print_section "Configuring WirePlumber"

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

print_section "Running custom scripts"

if [[ -f "$BUILDDIR/scripts/setup.sh" ]]; then

    info "Running scripts/setup.sh"

    chmod +x "$BUILDDIR/scripts/setup.sh"

    bash "$BUILDDIR/scripts/setup.sh"

fi

if [[ -f "$BUILDDIR/scripts/usenala" ]]; then

    info "Running scripts/usenala"

    chmod +x "$BUILDDIR/scripts/usenala"

    bash "$BUILDDIR/scripts/usenala"

fi

# ------------------------------------------------------------
# NVIDIA
# ------------------------------------------------------------

print_section "NVIDIA"

if [[ "$INSTALL_NVIDIA" == "true" ]]; then

    warning "NVIDIA installation has been requested."

    warning "This is intentionally disabled in this version."

else

    info "NVIDIA installation/update is disabled."

    if lspci 2>/dev/null | grep -qi nvidia; then

        info "NVIDIA hardware detected."

        echo
        echo "NVIDIA will NOT be installed or changed by this script."
        echo "We will handle NVIDIA manually after the base installation."
        echo

    else

        info "No NVIDIA hardware detected."

    fi

fi

# ------------------------------------------------------------
# Final cleanup
# ------------------------------------------------------------

print_section "Cleaning up"

apt-get autoremove -y
apt-get autoclean -y

# ------------------------------------------------------------
# Final permissions
# ------------------------------------------------------------

chown -R "$USERNAME:$USERNAME" "$USER_HOME"

# ------------------------------------------------------------
# Final repository check
# ------------------------------------------------------------

print_section "Checking APT repositories"

apt-get update

# ------------------------------------------------------------
# Display NVIDIA information
# ------------------------------------------------------------

print_section "NVIDIA status"

if lspci 2>/dev/null | grep -qi nvidia; then

    echo "NVIDIA hardware:"
    lspci | grep -i nvidia || true

    echo
    echo "Installed NVIDIA packages:"
    dpkg -l 2>/dev/null | grep -i nvidia || true

    echo
    echo "NVIDIA driver status:"
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi || true
    else
        echo "nvidia-smi is not installed."
    fi

else

    echo "No NVIDIA hardware detected."

fi

# ------------------------------------------------------------
# Finished
# ------------------------------------------------------------

print_section "Debian 13 setup complete"

echo "Hostname : $HOSTNAME"
echo "User     : $USERNAME"
echo "Debian   : 13 (Trixie)"
echo
echo "NVIDIA   : NOT managed by this installer"
echo
echo "The system will reboot in 10 seconds."
echo "Press Ctrl+C to cancel."
echo

sleep 10

systemctl reboot
