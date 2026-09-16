```bash
#!/bin/bash

# ============================================================
# HyperVeloce / Kanasu - User Environment Setup
# Debian 13 (Trixie)
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

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

# User who should receive the configuration.
# When this script is called by install.sh with sudo/root,
# SUDO_USER normally contains the original user.
TARGET_USER="${SUDO_USER:-${USER:-kanasu}}"

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

command_exists()
{
    command -v "$1" >/dev/null 2>&1
}

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
# Check Debian
# ------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    error "Cannot determine operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID:-}" != "debian" ]]; then
    error "This script is intended for Debian."
    exit 1
fi

if [[ "${VERSION_ID:-}" != "13" ]]; then
    error "This script is intended for Debian 13 (Trixie)."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

# ------------------------------------------------------------
# Check target user
# ------------------------------------------------------------

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

GITPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -d "$GITPATH" ]]; then
    error "Cannot find repository directory:"
    echo "$GITPATH"
    exit 1
fi

# ------------------------------------------------------------
# Check required commands
# ------------------------------------------------------------

check_environment()
{
    local missing=()

    for command in curl groups sudo git realpath getent; do
        if ! command_exists "$command"; then
            missing+=("$command")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands:"
        printf '  %s\n' "${missing[@]}"
        exit 1
    fi

    if ! groups "$TARGET_USER" | grep -Eq '(^|[[:space:]])sudo([[:space:]]|$)'; then
        warning "User $TARGET_USER is not currently a member of the sudo group."
        warning "Continuing because the main installer normally adds it."
    fi
}

# ------------------------------------------------------------
# Install dependencies
# ------------------------------------------------------------

install_dependencies()
{
    info "Installing shell dependencies..."

    export DEBIAN_FRONTEND=noninteractive

    apt-get update

    apt-get install -y \
        autojump \
        bash \
        bash-completion \
        bat \
        neovim \
        starship \
        tar

    success "Shell dependencies installed."
}

# ------------------------------------------------------------
# Configure Starship
# ------------------------------------------------------------

configure_starship()
{
    local STARSHIP_CONFIG="${USER_HOME}/.config/starship.toml"
    local SOURCE_FILE="${GITPATH}/${HOSTNAME}-starship.toml"

    info "Configuring Starship..."

    mkdir -p "${USER_HOME}/.config"

    if [[ -f "$SOURCE_FILE" ]]; then

        ln -sfn \
            "$SOURCE_FILE" \
            "$STARSHIP_CONFIG"

        success "Starship configuration linked."

    else

        warning "Starship configuration not found:"
        warning "$SOURCE_FILE"

    fi
}

# ------------------------------------------------------------
# Configure Bash
# ------------------------------------------------------------

configure_bash()
{
    local BASHRC="${USER_HOME}/.bashrc"
    local SOURCE_BASHRC="${GITPATH}/.bashrc"
    local BACKUP="${USER_HOME}/.bashrc.bak"

    info "Configuring Bash..."

    if [[ ! -f "$SOURCE_BASHRC" ]]; then
        warning "Repository .bashrc not found:"
        warning "$SOURCE_BASHRC"
        return
    fi

    # If .bashrc is already the correct symlink, nothing needs
    # to be changed.
    if [[ -L "$BASHRC" ]]; then

        if [[ "$(readlink -f "$BASHRC")" == "$(readlink -f "$SOURCE_BASHRC")" ]]; then
            success "Bash configuration already linked."
            return
        fi

    fi

    # Preserve an existing real .bashrc only once.
    if [[ -e "$BASHRC" && ! -L "$BASHRC" ]]; then

        if [[ ! -e "$BACKUP" ]]; then

            echo -e "${YELLOW}Backing up existing .bashrc to:${RC}"
            echo "$BACKUP"

            mv "$BASHRC" "$BACKUP"

        else

            warning "Existing .bashrc.bak found."
            warning "Leaving it untouched."

            rm -f "$BASHRC"

        fi

    else

        # Remove an old symlink that points somewhere else.
        rm -f "$BASHRC"

    fi

    ln -sfn \
        "$SOURCE_BASHRC" \
        "$BASHRC"

    success "Bash configuration linked."
}

# ------------------------------------------------------------
# Configure Neofetch
# ------------------------------------------------------------

configure_neofetch()
{
    local SOURCE="${GITPATH}/neofetchConfig.conf"
    local DEST="${USER_HOME}/.config/neofetch.conf"

    info "Configuring Neofetch..."

    if [[ ! -f "$SOURCE" ]]; then
        warning "Neofetch configuration not found."
        return
    fi

    mkdir -p "${USER_HOME}/.config"

    ln -sfn \
        "$SOURCE" \
        "$DEST"

    success "Neofetch configuration linked."
}

# ------------------------------------------------------------
# Configure Kitty
# ------------------------------------------------------------

configure_kitty()
{
    local KITTY_DIR="${USER_HOME}/.config/kitty"

    info "Configuring Kitty..."

    if [[ ! -d "${GITPATH}/kitty" ]]; then
        warning "Kitty configuration directory not found."
        return
    fi

    mkdir -p "$KITTY_DIR"

    if [[ -f "${GITPATH}/kitty/current-theme.conf" ]]; then
        ln -sfn \
            "${GITPATH}/kitty/current-theme.conf" \
            "${KITTY_DIR}/current-theme.conf"
    fi

    if [[ -f "${GITPATH}/kitty/kitty.conf" ]]; then
        ln -sfn \
            "${GITPATH}/kitty/kitty.conf" \
            "${KITTY_DIR}/kitty.conf"
    fi

    if [[ -f "${GITPATH}/kitty/theme.conf" ]]; then
        ln -sfn \
            "${GITPATH}/kitty/theme.conf" \
            "${KITTY_DIR}/theme.conf"
    fi

    success "Kitty configuration linked."
}

# ------------------------------------------------------------
# Configure Zed
# ------------------------------------------------------------

configure_zed()
{
    local ZED_DIR="${USER_HOME}/.config/zed"
    local SOURCE="${GITPATH}/zed/settings.conf"
    local DEST="${ZED_DIR}/settings.json"

    info "Configuring Zed..."

    if [[ ! -f "$SOURCE" ]]; then
        warning "Zed settings file not found:"
        warning "$SOURCE"
        return
    fi

    mkdir -p "$ZED_DIR"

    # Existing repository uses settings.conf.
    # Zed expects settings.json.
    ln -sfn \
        "$SOURCE" \
        "$DEST"

    success "Zed configuration linked."
}

# ------------------------------------------------------------
# Fix ownership
# ------------------------------------------------------------

fix_ownership()
{
    info "Fixing configuration ownership..."

    chown -R \
        "$TARGET_USER:$TARGET_USER" \
        "${USER_HOME}/.config" \
        2>/dev/null || true

    chown \
        "$TARGET_USER:$TARGET_USER" \
        "${USER_HOME}/.bashrc" \
        2>/dev/null || true

    if [[ -e "${USER_HOME}/.bashrc.bak" ]]; then
        chown \
            "$TARGET_USER:$TARGET_USER" \
            "${USER_HOME}/.bashrc.bak" \
            2>/dev/null || true
    fi

    success "Ownership updated."
}

# ------------------------------------------------------------
# Run
# ------------------------------------------------------------

echo
echo "============================================================"
echo " HyperVeloce user environment setup"
echo "============================================================"
echo
echo "Debian       : ${PRETTY_NAME:-Debian 13}"
echo "Target user  : $TARGET_USER"
echo "Home         : $USER_HOME"
echo "Repository   : $GITPATH"
echo

check_environment

install_dependencies

configure_bash
configure_starship
configure_neofetch
configure_kitty
configure_zed

fix_ownership

echo
echo "============================================================"
success "Setup complete!"
echo "============================================================"
echo
echo "Restart your shell or log out/in to see the changes."
echo
```
