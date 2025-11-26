#!/bin/bash

install -m 0755 -d /etc/at/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc -o /etc/apt/keyrings/microsoft.asc
chmod a+r /etc/apt/keyrings/microsoft.asc
tee /etc/apt/sources.list.d/vscode.sources <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/microsoft.gpg
EOF

# wget -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# apt install ./google-chrome-stable_current_amd64.deb

apt update
apt upgrade
apt install -y httpie keepassxc colordiff direnv zsh emacs-nox tmux ufw apt-transport-https ca-certificates curl gnupg2 software-properties-common powerline vim ripgrep aptitude libreoffice meld inkscape okular kontact imagemagick firefox make zlib1g zlib1g-dev fail2ban chkrootkit rkhunter network-manager-openvpn htop libbz2-1.0 libbz2-dev bzip2 libreadline-dev libzip-dev libssl-dev libffi-dev sshpass docker-ce docker-buildx-plugin docker-ce-cli containerd.io docker-compose-plugin google-chrome-stable code gdal-bin gdal-data python3-gdal libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev libffi-dev liblzma-dev uuid-dev tk-dev libgdbm-dev libnss3-dev libexpat1-dev libxml2-dev libxslt1-dev libjpeg-dev libfreetype-dev libpng-dev libpq-dev libcurl4-openssl-dev

chsh -s /usr/bin/zsh msmall
