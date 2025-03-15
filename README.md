# Debian-kanasu
Debian customizations from kanasu

### To install:

```
ssh-keygen -o -t rsa -C "davie.nguyen@gmail.com"
sudo apt install xclip git
xclip -sel clip < ~/.ssh/id_rsa.pub
```

```
git clone https://github.com/hyperveloce/debian.kanasu
cd debian.kanasu
chmod +x install.sh
sudo ./install.sh
```

```
sudo mount -t cifs //192.168.50.1/backup /mnt/ax6000 -o username=kserver,password=$$$$$,vers=2.0,uid=1000,gid=1000,iocharset=utf8

# CIFS mount for backup share
//192.168.50.1/backup  /mnt/ax6000  cifs  username=kserver,password=$$$$$,vers=2.0,uid=1000,gid=1000,iocharset=utf8  0  0

# CIFS mount for backup share with smbcredentials
/etc/smbcredentials

username=kserver
password=$$$$$

sudo chmod 600 /etc/smbcredentials

//192.168.50.1/backup  /mnt/ax6000  cifs  credentials=/etc/smbcredentials,vers=2.0,uid=1000,gid=1000,iocharset=utf8  0  0

```

## How to Set Timezone to Melbourne (SAMPLE) 

Run the following command:

```bash
sudo timedatectl set-timezone Australia/Melbourne
```

Verify the timezone:

```bash
timedatectl
```
