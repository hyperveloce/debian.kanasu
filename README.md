
# Setup Guide for Debian-kanasu and Postman Proxy

This guide includes setup instructions for custom Debian configurations and setting up the Postman Proxy.

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)  <!-- Optional Badge for Build Status -->

## Table of Contents

1. [Debian-kanasu Setup](#debian-kanasu-setup)
    1. [Install Debian-kanasu](#install-debian-kanasu)
    2. [Mount CIFS Share for Backup](#mount-cifs-share-for-backup)
    3. [Set Timezone](#set-timezone)
2. [Postman Proxy Setup](#postman-proxy-setup)
    1. [Generate and Install SSL Certificate](#generate-and-install-ssl-certificate)
3. [Additional Configuration](#additional-configuration)
    1. [Kitty Terminal Themes](#kitty-terminal-themes)
    2. [Titus Terminal and Fonts](#titus-terminal-and-fonts)

---

## Debian-kanasu Setup

### Install Debian-kanasu

1. **Generate SSH Key:**

    ```bash
    ssh-keygen -o -t rsa -C "your-email@example.com"
    sudo apt install xclip git
    xclip -sel clip < ~/.ssh/id_rsa.pub
    ```

2. **Clone the Repository and Run the Installer:**

    ```bash
    git clone https://github.com/hyperveloce/debian.kanasu
    cd debian.kanasu
    chmod +x install.sh
    sudo ./install.sh
    ```

### Mount CIFS Share for Backup

To mount a CIFS share for backup, run the following command:

```bash
sudo mount -t cifs //192.168.50.1/backup /mnt/ax6000 -o username=kserver,password=$$$$$,vers=2.0,uid=1000,gid=1000,iocharset=utf8
```

Alternatively, for persistent mounting, add the following entry to `/etc/fstab`:

```bash
//192.168.50.1/backup /mnt/ax6000 cifs username=kserver,password=$$$$$,vers=2.0,uid=1000,gid=1000,iocharset=utf8 0 0
```

For added security, use a separate credentials file:

1. Create `/etc/smbcredentials`:

    ```bash
    username=kserver
    password=$$$$$
    ```

2. Set the correct permissions for the file:

    ```bash
    sudo chmod 600 /etc/smbcredentials
    ```

3. Update `/etc/fstab`:

    ```bash
    //192.168.50.1/backup /mnt/ax6000 cifs credentials=/etc/smbcredentials,vers=2.0,uid=1000,gid=1000,iocharset=utf8 0 0
    ```

### Set Timezone

To set the timezone to Melbourne:

1. Run the following command:

    ```bash
    sudo timedatectl set-timezone Australia/Melbourne
    ```

2. Verify the current timezone:

    ```bash
    timedatectl
    ```

---

## Postman Proxy Setup

### Generate and Install SSL Certificate

To set up the Postman Proxy with a self-signed certificate:

```bash
cd ~/.var/app/com.getpostman.Postman/config/Postman/proxy
openssl req -subj '/C=US/CN=Postman Proxy' -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout postman-proxy-ca.key -out postman-proxy-ca.crt
```

For further details, refer to [this Gist](https://gist.github.com/pmkay/75faa1b926ba06416d0e44a29a584940).

---

## Additional Configuration

### Kitty Terminal Themes

Explore and apply custom themes for Kitty Terminal:

- [Kitty Overview](https://sw.kovidgoyal.net/kitty/overview/)
- [Tokyo Night Theme for Starship](https://starship.rs/presets/tokyo-night.html)

### Titus Terminal and Fonts

1. **Titus Terminal Bash Setup**:
   [GitHub Repository](https://github.com/ChrisTitusTech/mybash)
   [YouTube Video Guide](https://www.youtube.com/watch?v=XK7gal3Wrtk)

2. **Nerd Fonts for Bash**:
   [Meslo Nerd Font Release](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Meslo.zip)

---
