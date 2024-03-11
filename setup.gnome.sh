# # Quick Emulator & Virtual Machine Manager Nintendo Entertainment System (NES) emulator
# sudo apt install -y qemu-system virt-manager
# sudo apt install -y fceux
# sudo apt install -y dolphin-emu

# ----- Recording ----- #
# sudo apt install -y simplescreenrecorder
# sudo apt install -y obs-studio

# ----- Google Chrome ----- #
# wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# sudo apt install -y ./google-chrome-stable_current_amd64.deb
# rm google-chrome-stable_current_amd64.deb

# # ----- GitHub Desktop ----- #
# wget -qO - https://apt.packages.shiftkey.dev/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/shiftkey-packages.gpg > /dev/null
# sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main" > /etc/apt/sources.list.d/shiftkey-packages.list'
# sudo apt update
# sudo apt install github-desktop

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
# systemctl rebootD

# \cp ~/scripts/.bashrc ~
