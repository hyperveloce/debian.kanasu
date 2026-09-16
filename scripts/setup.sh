```bash
#!/bin/bash

# ============================================================
# HyperVeloce / Kanasu
# User environment setup for Debian 13 (Trixie)
#
# Safe to run repeatedly.
# Does NOT replace or symlink ~/.bashrc.
# Does NOT install, remove, or configure NVIDIA.
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
# Configuration
# ------------------------------------------------------------

# When called by install.sh with sudo/root, SUDO_USER is
# normally the user who started the installer.
TARGET_USER="${SUDO_USER:-${USER:-kanasu}}"

# Main installer uses kanasu. If setup.sh is executed directly
# as root without SUDO_USER, fall back to kanasu when present.
if [[ "$EUID" -eq 0 ]] && id kanasu >/dev/null 2>&1; then
    TARGET_USER="${SUDO_USER:-kanasu}"
fi

# ------------------------------------------------------------
# Basic checks
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
# Locate repository root
# ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -d "$REPO_DIR" ]]; then
    error "Cannot find repository directory:"
    echo "$REPO_DIR"
    exit 1
fi

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

echo
echo "============================================================"
echo " HyperVeloce user environment setup"
echo "============================================================"
echo
echo "Debian       : ${PRETTY_NAME:-Debian 13}"
echo "Target user  : $TARGET_USER"
echo "Home         : $USER_HOME"
echo "Repository   : $REPO_DIR"
echo

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then
    error "This script must be run with root privileges."
    echo
    echo "Run:"
    echo "  sudo ./scripts/setup.sh"
    exit 1
fi

# ------------------------------------------------------------
# Install shell dependencies
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
# Configure ~/.bashrc safely
#
# IMPORTANT:
# We deliberately do NOT replace ~/.bashrc.
# We append one managed block only when needed.
# ------------------------------------------------------------

configure_bash()
{
    local BASHRC="${USER_HOME}/.bashrc"
    local MARKER_START="# >>> HyperVeloce Kanasu setup >>>"
    local MARKER_END="# <<< HyperVeloce Kanasu setup <<<"

    info "Configuring Bash..."

    # If .bashrc is a broken symlink, remove it before creating
    # the normal configuration file.
    if [[ -L "$BASHRC" && ! -e "$BASHRC" ]]; then
        warning "Removing broken ~/.bashrc symlink."
        rm -f "$BASHRC"
    fi

    # If ~/.bashrc does not exist, create a normal file.
    if [[ ! -e "$BASHRC" ]]; then
        touch "$BASHRC"
    fi

    # Never allow ~/.bashrc to point at this installer.
    if [[ -L "$BASHRC" ]]; then
        local resolved
        resolved="$(readlink -f "$BASHRC" 2>/dev/null || true)"

        if [[ "$resolved" == "$REPO_DIR/scripts/.bashrc" ]]; then
            warning "Found unsafe ~/.bashrc symlink to scripts/.bashrc."
            warning "Replacing it with a normal ~/.bashrc file."

            rm -f "$BASHRC"

            if [[ -f "${USER_HOME}/.bashrc.bak" ]]; then
                cp "${USER_HOME}/.bashrc.bak" "$BASHRC"
            else
                touch "$BASHRC"
            fi
        else
            warning "Existing ~/.bashrc is a symlink."
            warning "Leaving the existing symlink untouched."
        fi
    fi

    # Only modify a regular ~/.bashrc.
    if [[ -f "$BASHRC" && ! -L "$BASHRC" ]]; then

        if ! grep -Fq "$MARKER_START" "$BASHRC"; then

            cat >> "$BASHRC" <<'EOF'

# >>> HyperVeloce Kanasu setup >>>

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Autojump
if [[ -f /usr/share/autojump/autojump.sh ]]; then
    source /usr/share/autojump/autojump.sh
fi

# Debian installs bat as batcat.
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    alias bat='batcat'
fi

# <<< HyperVeloce Kanasu setup <<<
EOF

            success "Bash configuration added."
        else
            success "Bash configuration already present."
        fi
    fi

    chown "$TARGET_USER:$TARGET_USER" "$BASHRC"
}

# ------------------------------------------------------------
# Configure Starship
#
# We only link a Starship configuration if one actually exists.
# No failure if the repository does not contain one.
# ------------------------------------------------------------

configure_starship()
{
    local CONFIG_DIR="${USER_HOME}/.config"
    local DEST="${CONFIG_DIR}/starship.toml"
    local SOURCE=""

    info "Checking Starship configuration..."

    mkdir -p "$CONFIG_DIR"

    # Check likely repository locations.
    if [[ -f "${REPO_DIR}/starship.toml" ]]; then
        SOURCE="${REPO_DIR}/starship.toml"
    elif [[ -f "${REPO_DIR}/${HOSTNAME}-starship.toml" ]]; then
        SOURCE="${REPO_DIR}/${HOSTNAME}-starship.toml"
    elif [[ -f "${REPO_DIR}/scripts/starship.toml" ]]; then
        SOURCE="${REPO_DIR}/scripts/starship.toml"
    elif [[ -f "${REPO_DIR}/scripts/${HOSTNAME}-starship.toml" ]]; then
        SOURCE="${REPO_DIR}/scripts/${HOSTNAME}-starship.toml"
    fi

    if [[ -n "$SOURCE" ]]; then
        ln -sfn "$SOURCE" "$DEST"
        chown -h "$TARGET_USER:$TARGET_USER" "$DEST"
        success "Starship configuration linked."
    else
        warning "No repository Starship configuration found."
        warning "Using Starship's default configuration."
    fi
}

# ------------------------------------------------------------
# Configure Kitty
# ------------------------------------------------------------

configure_kitty()
{
    local SOURCE_DIR="${REPO_DIR}/scripts/kitty"
    local DEST_DIR="${USER_HOME}/.config/kitty"

    info "Configuring Kitty..."

    if [[ ! -d "$SOURCE_DIR" ]]; then
        warning "Repository Kitty directory not found."
        return
    fi

    mkdir -p "$DEST_DIR"

    for file in \
        current-theme.conf \
        kitty.conf \
        theme.conf
    do
        if [[ -f "${SOURCE_DIR}/${file}" ]]; then
            ln -sfn \
                "${SOURCE_DIR}/${file}" \
                "${DEST_DIR}/${file}"
        fi
    done

    chown -R "$TARGET_USER:$TARGET_USER" "$DEST_DIR"

    success "Kitty configuration updated."
}

# ------------------------------------------------------------
# Remove the dangerous legacy repository .bashrc only if it is
# clearly the accidental installer file.
#
# This does NOT delete ~/.bashrc.
# ------------------------------------------------------------

check_legacy_repository_bashrc()
{
    local FILE="${REPO_DIR}/scripts/.bashrc"

    if [[ ! -f "$FILE" ]]; then
        return
    fi

    if grep -q '^# HyperVeloce / Kanasu - User Environment Setup' "$FILE" \
        && grep -q '^configure_bash' "$FILE"; then

        warning "The repository contains the old accidental scripts/.bashrc file."
        warning "This file is an installer, not a Bash configuration."
        warning "It will NOT be linked to ~/.bashrc."

        # Rename rather than delete, preserving the file in case the
        # repository is still being cleaned up manually.
        local BACKUP="${REPO_DIR}/scripts/.bashrc.installer"

        if [[ ! -e "$BACKUP" ]]; then
            mv "$FILE" "$BACKUP"
            success "Moved old scripts/.bashrc to scripts/.bashrc.installer."
        else
            rm -f "$FILE"
            success "Removed duplicate old scripts/.bashrc."
        fi
    fi
}

# ------------------------------------------------------------
# Ownership
# ------------------------------------------------------------

fix_ownership()
{
    info "Fixing ownership..."

    chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.bashrc" 2>/dev/null || true
    chown -R "$TARGET_USER:$TARGET_USER" \
        "$USER_HOME/.config" \
        2>/dev/null || true

    success "Ownership updated."
}

# ------------------------------------------------------------
# Run
# ------------------------------------------------------------

install_dependencies
check_legacy_repository_bashrc
configure_bash
configure_starship
configure_kitty
fix_ownership

echo
echo "============================================================"
success "Setup complete."
echo "============================================================"
echo
echo "Your existing ~/.bashrc was preserved."
echo "The installer will not replace ~/.bashrc with a symlink."
echo "NVIDIA was not modified."
echo
echo "Restart your terminal after the main installer finishes."
echo
```
