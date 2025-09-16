#!/bin/bash

# Update and upgrade existing setup
sudo apt update
sudo apt upgrade

# Install generic apps wanted
sudo apt install -y zsh emacs-nox tmux apt-transport-https aptitude ca-certificates curl gnupg2 imagemagick inkscape meld ripgrep software-properties-common powerline vim jq keepassxc

# Setup GPG keyring
sudo mkdir -p /etc/apt/keyrings

# Docker setup
# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Helm
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# Add repo with explicit signed-by
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

## VS Code setup
# Import Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg

# Add repo with explicit signed-by
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] http://packages.microsoft.com/repos/vscode stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

# Google Chrome
# Import Google's GPG key
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg

# Add repo with explicit signed-by
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# # Setup YAML CLI parser
sudo add-apt-repository -y ppa:rmescandon/yq

# Re-update the sources list
sudo apt update

# Install from imported PPAs
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin helm code google-chrome-stable jq

# For python
sudo apt install -y libssl-dev zlib1g-dev libbz2-dev libsqlite3-dev libffi-dev liblzma-dev libreadline-dev tk-dev
