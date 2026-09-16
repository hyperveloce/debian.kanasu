```bash
#!/bin/bash

# ============================================================
# HyperVeloce / Kanasu
# Debian 13 (Trixie) user-tool setup
#
# IMPORTANT:
#   - Safe to run repeatedly
#   - NEVER replaces ~/.bashrc
#   - NEVER creates a ~/.bashrc symlink
#   - NEVER executes repository files as shell startup files
#   - Does NOT install, remove, or configure NVIDIA
#
# The main install.sh already handles:
#   - system packages
#   - desktop configuration
#   - ~/.config
#   - Kitty
#   - Neovim
#   - Fastfetch
#   - Zoxide
#   - themes/fonts
#   - GNOME configuration
#
# This script only handles a few shell utilities that are not
# part of the main package list.
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Colours
# ------------------------------------------------------------

RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'
BLUE='\e[34m'

info()
{
    echo -e "${BLUE}$1${RC}"
}

success()
{
    echo -e "${GREEN}$1${RC}"
}

warning()
{
    echo -e "${YELLOW}$1${RC}"
}

error()
{
    echo -e "${RED}$1${RC}"
}

# ------------------------------------------------------------
# Must run as root
# ------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then
    error "This script must be run as root."
    echo
    echo "Run:"
    echo "  sudo ./scripts/setup.sh"
    exit 1
fi

# ------------------------------------------------------------
# Check Debian
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

# ------------------------------------------------------------
# Determine target user
# ------------------------------------------------------------

TARGET_USER="${SUDO_USER:-}"

if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    if id kanasu >/dev/null 2>&1; then
        TARGET_USER="kanasu"
    else
        TARGET_USER="${USER:-}"
    fi
fi

if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    error "Could not determine the normal desktop user."
    exit 1
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
    error "User '$TARGET_USER' does not exist."
    exit 1
fi

USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    error "Could not determine home directory for $TARGET_USER."
    exit 1
fi

# ------------------------------------------------------------
# Locate repository
# ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

echo
echo "============================================================"
echo " HyperVeloce / Kanasu - shell tools"
echo "============================================================"
echo
echo "Debian      : ${PRETTY_NAME:-unknown}"
echo "User        : $TARGET_USER"
echo "Home        : $USER_HOME"
echo "Repository  : $REPO_DIR"
echo

# ------------------------------------------------------------
# Install shell utilities
# ------------------------------------------------------------

info "Installing shell utilities..."

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
    autojump \
    bash-completion \
    bat \
    neovim \
    starship \
    tar

success "Shell utilities installed."

# ------------------------------------------------------------
# Check .bashrc
#
# We deliberately DO NOT edit it.
# We only detect the old dangerous symlink and stop.
# ------------------------------------------------------------

BASHRC="$USER_HOME/.bashrc"

echo
info "Checking ~/.bashrc..."

if [[ -L "$BASHRC" ]]; then

    BASHRC_TARGET="$(readlink -f "$BASHRC" 2>/dev/null || true)"

    warning "~/.bashrc is currently a symbolic link:"
    echo "  $BASHRC -> $BASHRC_TARGET"

    if [[ "$BASHRC_TARGET" == "$REPO_DIR/scripts/.bashrc" ]]; then
        error "DANGEROUS configuration detected."
        echo
        echo "~/.bashrc points to scripts/.bashrc."
        echo "The repository file must never be used as ~/.bashrc."
        echo
        echo "This script will NOT modify it automatically."
        echo "Restore ~/.bashrc before continuing."
        echo
        exit 1
    fi

    warning "Existing ~/.bashrc symlink detected."
    warning "Leaving it unchanged."

elif [[ -f "$BASHRC" ]]; then

    success "~/.bashrc is a normal file."
    
elif [[ ! -e "$BASHRC" ]]; then

    warning "~/.bashrc does not exist."

    if [[ -f /etc/skel/.bashrc ]]; then
        cp /etc/skel/.bashrc "$BASHRC"
        chown "$TARGET_USER:$TARGET_USER" "$BASHRC"
        chmod 644 "$BASHRC"
        success "Created ~/.bashrc from /etc/skel/.bashrc."
    else
        touch "$BASHRC"
        chown "$TARGET_USER:$TARGET_USER" "$BASHRC"
        chmod 644 "$BASHRC"
        warning "Created an empty ~/.bashrc."
    fi

fi

# ------------------------------------------------------------
# Check old accidental repository file
#
# Do not use it.
# Do not link it.
# Do not source it.
# ------------------------------------------------------------

LEGACY_BASHRC="$REPO_DIR/scripts/.bashrc"

if [[ -f "$LEGACY_BASHRC" ]]; then

    if grep -q 'configure_bash' "$LEGACY_BASHRC" 2>/dev/null; then
        warning "Found legacy scripts/.bashrc installer file."
        warning "It will NOT be used as a shell configuration."
    fi

fi

# ------------------------------------------------------------
# Optional Starship configuration
#
# The main installer owns ~/.config.
# We only report whether a Starship config exists.
# ------------------------------------------------------------

echo
info "Checking Starship configuration..."

STARSHIP_CONFIG=""

if [[ -f "$REPO_DIR/starship.toml" ]]; then
    STARSHIP_CONFIG="$REPO_DIR/starship.toml"
elif [[ -f "$REPO_DIR/${HOSTNAME}-starship.toml" ]]; then
    STARSHIP_CONFIG="$REPO_DIR/${HOSTNAME}-starship.toml"
elif [[ -f "$REPO_DIR/scripts/starship.toml" ]]; then
    STARSHIP_CONFIG="$REPO_DIR/scripts/starship.toml"
elif [[ -f "$REPO_DIR/scripts/${HOSTNAME}-starship.toml" ]]; then
    STARSHIP_CONFIG="$REPO_DIR/scripts/${HOSTNAME}-starship.toml"
fi

if [[ -n "$STARSHIP_CONFIG" ]]; then
    echo "Starship configuration found:"
    echo "  $STARSHIP_CONFIG"
    echo
    echo "Configuration linking is left to the main installer."
else
    warning "No repository Starship configuration found."
    warning "Starship will use its default configuration."
fi

# ------------------------------------------------------------
# Final ownership check
# ------------------------------------------------------------

chown "$TARGET_USER:$TARGET_USER" "$BASHRC" 2>/dev/null || true

# ------------------------------------------------------------
# Final status
# ------------------------------------------------------------

echo
echo "============================================================"
success "Shell setup complete."
echo "============================================================"
echo
echo "Installed:"
echo "  autojump"
echo "  bash-completion"
echo "  bat"
echo "  neovim"
echo "  starship"
echo "  tar"
echo
echo "NVIDIA: untouched"
echo
echo "~/.bashrc: NOT replaced or symlinked"
echo
```
