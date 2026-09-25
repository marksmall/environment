#!/bin/bash
# Run as your normal user; privileged steps use sudo.
# Fail fast on errors, unset vars, and pipeline failures.
#set -euo pipefail

# Central keyring directory for apt sources.
sudo install -m 0755 -d /etc/apt/keyrings

# Docker and HashiCorp publish no Debian testing (forky) suites, so these use
# Ubuntu noble, which installs and runs fine on testing.

# Docker: add vendor key and repository.
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
sudo chmod 0644 /etc/apt/keyrings/docker.gpg
# Apt source file uses signed-by to scope trust to this key.
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Signed-By: /etc/apt/keyrings/docker.gpg
EOF

# VS Code: add Microsoft key and repository.
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod 0644 /etc/apt/keyrings/microsoft.gpg
# Apt source file uses signed-by to scope trust to this key.
sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/microsoft.gpg
EOF

# Terraform: add HashiCorp key and repository.
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/hashicorp.gpg > /dev/null
sudo chmod 0644 /etc/apt/keyrings/hashicorp.gpg
# Use the system architecture for the repo entry.
sudo tee /etc/apt/sources.list.d/hashicorp.sources > /dev/null <<EOF
Types: deb
URIs: https://apt.releases.hashicorp.com
Suites: noble
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/hashicorp.gpg
EOF

# Google Chrome: add Google key and repository.
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/google-chrome.gpg > /dev/null
sudo chmod 0644 /etc/apt/keyrings/google-chrome.gpg
# Apt source file uses signed-by to scope trust to this key.
sudo tee /etc/apt/sources.list.d/google-chrome.sources > /dev/null <<EOF
Types: deb
URIs: https://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/google-chrome.gpg
EOF

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
sudo chmod 0644 /etc/apt/keyrings/githubcli-archive-keyring.gpg
sudo tee /etc/apt/sources.list.d/github-cli.sources > /dev/null <<EOF
Types: deb
URIs: https://cli.github.com/packages
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/githubcli-archive-keyring.gpg
EOF

# DBeaver database (flat repository: Suites "/" and no Components).
curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/dbeaver.gpg >/dev/null
sudo chmod 0644 /etc/apt/keyrings/dbeaver.gpg
sudo tee /etc/apt/sources.list.d/dbeaver.sources > /dev/null <<EOF
Types: deb
URIs: https://dbeaver.io/debs/dbeaver-ce/
Suites: /
Signed-By: /etc/apt/keyrings/dbeaver.gpg
EOF

# Atlassian CLI (acli): add Atlassian key and repository.
curl -fsSL https://acli.atlassian.com/gpg/public-key.asc | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/acli.gpg > /dev/null
sudo chmod 0644 /etc/apt/keyrings/acli.gpg
sudo tee /etc/apt/sources.list.d/acli.sources > /dev/null <<EOF
Types: deb
URIs: https://acli.atlassian.com/linux/deb
Suites: stable
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/acli.gpg
EOF

# Refresh package lists and apply upgrades.
sudo apt update
sudo apt upgrade -y

# Base packages for CLI, desktop, dev, and build tooling.
# (An array, because comments can't sit inside a backslash-continued command.)
packages=(
  # Shell and CLI tools
  aptitude ca-certificates colordiff curl direnv fd-find fzf gh git-delta
  glow gnupg2 httpie htop jq powerline ripgrep
  sshpass tmux ufw vim yq zsh
  # Editors and desktop apps
  dbeaver-ce emacs-nox firefox-esr imagemagick inkscape keepassxc kontact
  libreoffice meld okular
  # Security and system utilities
  chkrootkit fail2ban network-manager-openvpn rkhunter
  # Container tooling
  containerd.io docker-buildx-plugin docker-ce docker-ce-cli
  docker-compose-plugin
  # Developer tools
  acli code google-chrome-stable make terraform
  # GIS tooling
  gdal-bin gdal-data python3-gdal
  # Build dependencies (mise builds python etc. from source)
  bzip2 libbz2-1.0 libbz2-dev libcurl4-openssl-dev
  libexpat1-dev libffi-dev libfreetype-dev libgdbm-dev
  libjpeg-dev liblzma-dev libncursesw5-dev libnss3-dev
  libpng-dev libpq-dev libreadline-dev libsqlite3-dev libssl-dev
  libxml2-dev libxslt1-dev libzip-dev tk-dev uuid-dev zlib1g
  zlib1g-dev
)
sudo apt install -y "${packages[@]}"

# Switch the login shell to zsh if available and not already set.
if [ "${SHELL}" != "/usr/bin/zsh" ] && \
  [ -x "/usr/bin/zsh" ] && \
  grep -qx "/usr/bin/zsh" /etc/shells; then
  chsh -s /usr/bin/zsh "${USER}"
fi
