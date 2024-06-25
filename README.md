# Debian-kanasu
Debian customizations from kanasu

### To install:

```
ssh-keygen -o -t rsa -C "davie.nguyen@gmail.com"
xclip -sel clip < ~/.ssh/id_rsa.pub
```


```
git clone https://github.com/hyperveloce/debian.kanasu
cd debian.kanasu
sudo ./install.sh
```



```
sudo apt install curl
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install brave-browser
```
