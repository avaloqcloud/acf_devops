#!/usr/bin/env bash

# Constants
readonly CMD_SHUTDOWN="shutdown -P now; init 0"

# Exit on error
set -e

#######################################
# Print usage message and exit
#######################################
update() {
  echo "Updating Linux Environment"
  apt update -y && apt upgrade -y
  touch ./install.log
}

#######################################
# Print error message and exit
#######################################
error() {
  echo "$(tput setaf 1)+++ : $*$(tput sgr 0)" >&2
  exit 1
}

#######################################
# Input user credentials for git
#######################################
input_user() {
    local USR
    echo "Provide your username for git config"  >&2
    read -p "Username: " USR
    echo $USR
}

input_email() {
    local EML
    echo "Provide your eMail for git config" >&2
    read -p "eMail: " EML
    echo $EML
}

#######################################
# Install developer tools
#######################################
install_python() {
  clear
  echo "Installing python"
  apt install build-essential -y 
  apt install libssl-dev -y 
  apt install libffi-dev -y 
  apt install python3-pip -y 
  PYTHON_VERSION=$(python3 --version)
  echo "Installed Python3 $PYTHON_VERSION" >> ./install.log
}

#######################################
# Nano Editor
#######################################
install_nano() {
  clear
  echo "Installing nano"
  apt install nano -y
  NANO_VERSION=$(nano --version)
  echo "Installed Nano $NANO_VERSION" >> ./install.log
}

#######################################
# Git
#######################################
install_git() {
  clear
  echo "Installing git"
  apt-get install git -y
  apt-get install libnss3-dev -y
  git config --global core.editor "nano"
  type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
  GIT_VERSION=$(git --version)
  GH_VERSION=$(gh --version)
  echo "Installed Git $GIT_VERSION and GH $GH_VERSION" >> ./install.log
}

#######################################
# Git config
#######################################
config_git() {
  clear
  echo "Installing git"
  GITNAME=$(input_user)
  GITMAIL=$(input_email)
  git config --global user.name $GITNAME
  git config --global user.email $GITMAIL
  echo "Configured Git" >> ./install.log
}

#######################################
# PostgreSQL
#######################################
install_psql() {
  clear
  echo "Installing PostgreSQL"
  apt install -y postgresql 
  apt install -y postgresql-contrib
  PSQL_VERSION=$(psql --version)
  echo "Installed PSQL $PSQL_VERSION" >> ./install.log
}

#######################################
# Visual Studio Code
#######################################
install_vsc() {
  clear
  echo "Installing VSCode"
  apt-get install wget gpg
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg
  apt install apt-transport-https
  apt update
  apt install code -y
}

#######################################
# Terraform
#######################################
install_terraform() {
  clear
  echo "Installing Terraform"
  apt install -y gnupg software-properties-common
  wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
  gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list
  apt update
  apt install terraform -y
  TF_VERSION=$(terraform version)
  echo "Installed Terraform $TF_VERSION" >> ./install.log
}

#######################################
# Main
#######################################
main () {
  update
  install_python
  install_nano
  install_git
  install_psql
  install_vsc
  install_terraform
  echo "All done" && exit 1
}

main "$@"
