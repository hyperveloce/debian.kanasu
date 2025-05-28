#!/bin/bash

# Update and Upgrade APT (Debian Packages)
echo -e "\n\033[1;32mUpdating APT packages...\033[0m"
sudo apt update
sudo apt upgrade -y
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt clean
sudo apt autoclean

# Update Snaps (if installed)
echo -e "\n\033[1;32mUpdating Snaps...\033[0m"
if command -v snap &> /dev/null; then
    sudo snap refresh
else
    echo "Snap not installed. Skipping."
fi

# Update Firmware (fwupd)
echo -e "\n\033[1;32mChecking for firmware updates...\033[0m"
if command -v fwupdmgr &> /dev/null; then
    sudo fwupdmgr refresh
    sudo fwupdmgr update
else
    echo "fwupd (firmware updater) not installed. Skipping."
fi

# Check for Python (pip) updates
echo -e "\n\033[1;32mChecking for outdated Python packages...\033[0m"
if command -v pip &> /dev/null; then
    pip list --outdated
    echo "To upgrade Python packages, run: pip install --upgrade <package>"
else
    echo "pip not found. Skipping."
fi

# Check for Node.js (npm) updates
echo -e "\n\033[1;32mChecking for outdated global npm packages...\033[0m"
if command -v npm &> /dev/null; then
    npm outdated -g
    echo "To upgrade npm packages, run: npm update -g"
else
    echo "npm not found. Skipping."
fi

# Final message
echo -e "\n\033[1;32mSystem update completed!\033[0m"
echo "If the kernel or firmware was updated, consider rebooting."
