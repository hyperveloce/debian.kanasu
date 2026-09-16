```bash
# HyperVeloce / Kanasu
# Debian 13 user-environment setup
#
# Safe to run repeatedly.
#
# IMPORTANT:
#   - NEVER replaces ~/.bashrc
#   - NEVER symlinks ~/.bashrc
#   - NEVER sources repository scripts from ~/.bashrc
#   - NEVER installs/configures NVIDIA
#
# Responsibilities:
#   - Install shell utilities
#   - Configure Starship when a repo config exists
#   - Configure autojump
#   - Configure bat/batcat
#   - Configure Kitty from the repo
#   - Preserve the user's existing ~/.bashrc
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

USERNAME="${SUDO_USER:-kanasu}"

if [[ "$USERNAME" == "root" || -z "$USERNAME" ]]; then
    USERNAME="kanasu"
fi

if ! id "$USERNAME" >/dev/null 2>&1; then
    echo "ERROR: User '$USERNAME' does not exist."
    exit 1
fi

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BASHRC="$USER_HOME/.bashrc"
CONFIG_DIR="$USER_HOME/.config"
KITTY_DIR="$CONFIG_DIR/kitty"

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    echo
    echo "Example:"
    echo "  sudo ./scripts/setup.sh"
    exit 1
fi

# ------------------------------------------------------------
# Debian 13 check
# ------------------------------------------------------------

source /etc/os-release

if [[ "${ID:-}" != "debian" || "${VERSION_ID:-}" != "13" ]]; then
    echo "ERROR: This script is intended for Debian 13 (Trixie)."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

echo
echo "============================================================"
echo " HyperVeloce / Kanasu user setup"
echo "============================================================"
echo
echo "User       : $USERNAME"
echo "Home       : $USER_HOME"
echo "Repository : $REPO_DIR"
echo

# ------------------------------------------------------------
# Install shell packages
# ------------------------------------------------------------

echo "Installing shell packages..."

apt-get update

apt-get install -y \
    autojump \
    bash-completion \
    bat \
    neovim \
    starship \
    tar

echo "Shell packages installed."

# ------------------------------------------------------------
# SAFETY CHECK
#
# ~/.bashrc must never point at scripts/.bashrc.
# ------------------------------------------------------------

echo
echo "Checking ~/.bashrc..."

if [[ -L "$BASHRC" ]]; then

    TARGET="$(readlink -f "$BASHRC" 2>/dev/null || true)"

    echo "WARNING: ~/.bashrc is a symlink:"
    echo "  $BASHRC -> $TARGET"

    if [[ "$TARGET" == "$REPO_DIR/scripts/.bashrc" ]]; then
        echo
        echo "ERROR: ~/.bashrc points to the installer."
        echo "This would cause recursive Bash execution."
        echo
        echo "The script will stop without changing ~/.bashrc."
        exit 1
    fi

elif [[ -f "$BASHRC" ]]; then

    echo "OK: ~/.bashrc is a normal file."

elif [[ ! -e "$BASHRC" ]]; then

    echo "~/.bashrc does not exist."
    echo "Creating it from /etc/skel/.bashrc..."

    if [[ -f /etc/skel/.bashrc ]]; then
        cp /etc/skel/.bashrc "$BASHRC"
    else
        touch "$BASHRC"
    fi

    chown "$USERNAME:$USERNAME" "$BASHRC"
    chmod 644 "$BASHRC"

    echo "~/.bashrc created."

fi

# ------------------------------------------------------------
# Remove old accidental scripts/.bashrc
#
# This file was previously an installer accidentally named
# .bashrc. It must never be used as a shell startup file.
#
# Rename rather than delete the first time.
# ------------------------------------------------------------

LEGACY_BASHRC="$REPO_DIR/scripts/.bashrc"
LEGACY_BACKUP="$REPO_DIR/scripts/.bashrc.installer"

if [[ -f "$LEGACY_BASHRC" ]]; then

    if grep -q "configure_bash" "$LEGACY_BASHRC" 2>/dev/null; then

        echo
        echo "Found legacy installer named scripts/.bashrc."

        if [[ ! -e "$LEGACY_BACKUP" ]]; then
            mv "$LEGACY_BASHRC" "$LEGACY_BACKUP"
            echo "Moved:"
            echo "  scripts/.bashrc"
            echo "to:"
            echo "  scripts/.bashrc.installer"
        else
            rm -f "$LEGACY_BASHRC"
            echo "Removed duplicate legacy scripts/.bashrc."
        fi

    fi

fi

# ------------------------------------------------------------
# Bash helper configuration
#
# We append ONE managed block only if it doesn't already exist.
#
# We do NOT overwrite the user's .bashrc.
# ------------------------------------------------------------

BASH_MARKER="# >>> HyperVeloce Kanasu managed setup >>>"

if [[ -f "$BASHRC" && ! -L "$BASHRC" ]]; then

    if ! grep -Fq "$BASH_MARKER" "$BASHRC"; then

        cat >> "$BASHRC" <<'EOF'

# >>> HyperVeloce Kanasu managed setup >>>

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

# <<< HyperVeloce Kanasu managed setup <<<

EOF

        echo "Bash helpers added to ~/.bashrc."

    else

        echo "Bash helpers already configured."

    fi

fi

# ------------------------------------------------------------
# Starship configuration
#
# Only link a real configuration file.
# ------------------------------------------------------------

echo
echo "Checking Starship configuration..."

STARSHIP_SOURCE=""

for candidate in \
    "$REPO_DIR/starship.toml" \
    "$REPO_DIR/$HOSTNAME-starship.toml" \
    "$REPO_DIR/scripts/starship.toml" \
    "$REPO_DIR/scripts/$HOSTNAME-starship.toml"
do
    if [[ -f "$candidate" ]]; then
        STARSHIP_SOURCE="$candidate"
        break
    fi
done

mkdir -p "$CONFIG_DIR"

if [[ -n "$STARSHIP_SOURCE" ]]; then

    ln -sfn "$STARSHIP_SOURCE" "$CONFIG_DIR/starship.toml"
    echo "Starship configuration linked:"
    echo "  $STARSHIP_SOURCE"

else

    echo "No repository Starship configuration found."
    echo "Starship will use its default configuration."

fi

# ------------------------------------------------------------
# Kitty configuration
# ------------------------------------------------------------

echo
echo "Configuring Kitty..."

KITTY_SOURCE="$REPO_DIR/scripts/kitty"

if [[ -d "$KITTY_SOURCE" ]]; then

    mkdir -p "$KITTY_DIR"

    for FILE in \
        kitty.conf \
        theme.conf \
        current-theme.conf
    do

        if [[ -f "$KITTY_SOURCE/$FILE" ]]; then

            ln -sfn \
                "$KITTY_SOURCE/$FILE" \
                "$KITTY_DIR/$FILE"

            echo "Linked Kitty $FILE"

        fi

    done

    chown -R "$USERNAME:$USERNAME" "$KITTY_DIR"

else

    echo "Kitty repository configuration not found."
    echo "Skipping Kitty configuration."

fi

# ------------------------------------------------------------
# Zed
#
# The current repository does not contain the old settings.conf
# path, so don't manufacture or link a nonexistent file.
# ------------------------------------------------------------

echo
echo "Checking Zed configuration..."

if [[ -f "$REPO_DIR/zed/settings.json" ]]; then

    mkdir -p "$CONFIG_DIR/zed"

    ln -sfn \
        "$REPO_DIR/zed/settings.json" \
        "$CONFIG_DIR/zed/settings.json"

    chown -R "$USERNAME:$USERNAME" "$CONFIG_DIR/zed"

    echo "Zed settings linked."

elif [[ -f "$REPO_DIR/scripts/zed/settings.json" ]]; then

    mkdir -p "$CONFIG_DIR/zed"

    ln -sfn \
        "$REPO_DIR/scripts/zed/settings.json" \
        "$CONFIG_DIR/zed/settings.json"

    chown -R "$USERNAME:$USERNAME" "$CONFIG_DIR/zed"

    echo "Zed settings linked."

else

    echo "No Zed settings file found."
    echo "Skipping Zed configuration."

fi

# ------------------------------------------------------------
# Ownership
# ------------------------------------------------------------

echo
echo "Fixing ownership..."

chown "$USERNAME:$USERNAME" "$BASHRC" 2>/dev/null || true
chown -R "$USERNAME:$USERNAME" "$CONFIG_DIR" 2>/dev/null || true

# ------------------------------------------------------------
# NVIDIA
# ------------------------------------------------------------

echo
echo "NVIDIA: untouched."

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------

echo
echo "============================================================"
echo " User setup complete"
echo "============================================================"
echo
echo "Configured:"
echo "  - shell packages"
echo "  - Bash helpers"
echo "  - Starship (when config exists)"
echo "  - Kitty configuration"
echo
echo "~/.bashrc was NOT replaced or symlinked."
echo "NVIDIA was NOT modified."
echo
```
