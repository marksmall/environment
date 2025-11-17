#!/bin/bash

apt install -y zsh emacs-nox tmux ufw apt-transport-https ca-certificates curl gnupg2 software-properties-common powerline vim ripgrep aptitude libreoffice meld inkscape okular kontact imagemagick firefox choqok sddm-theme-breeze sddm-theme-debian-breeze make zlib1g zlib1g-dev fail2ban chkrootkit rkhunter network-manager-openvpn htop libbz2-1.0 libbz2-dev bzip2 libreadline-dev libzip-dev libssl-dev libffi-dev sshpass

#curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
#add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian buster stable"
apt-get remove docker docker-engine docker.io containerd runc
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add -
add-apt-repository "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main"

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install ./google-chrome-stable_current_amd64.deb

wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O- | sudo apt-key add -

apt upgrade
apt install -y docker-ce docker-ce-cli containerd.io docker-compose google-chrome-stable code postgresql

# Install ansible binaries.
pip install ansible
