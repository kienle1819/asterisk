#!/bin/bash
###############################################################################
# Script Name    : script_asterisk_20                       
# Description    : Script to install Asterisk 20 on Ubuntu & Debian              
# Author         : Mr.Kien Le    
################################################################################

# Update system & reboot
sudo apt update && sudo apt -y upgrade

echo "System updated. Reboot is recommended. Do you want to reboot now? (y/n)"
read -r REBOOT

if [[ "$REBOOT" == "y" || "$REBOOT" == "Y" ]]; then
  sudo reboot
else
  echo "Continuing without reboot..."
fi

# Install Asterisk 20 LTS dependencies
sudo apt -y install git curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev uuid-dev

# Add universe repository and install subversion
sudo add-apt-repository universe
sudo apt update && sudo apt -y install subversion

# Download Asterisk 20 LTS tarball
cd /usr/src/
sudo curl -O http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz

# Extract the file
sudo tar xvf asterisk-20-current.tar.gz
cd asterisk-20*/

# Download the mp3 decoder library
sudo contrib/scripts/get_mp3_source.sh

# Ensure all dependencies are resolved
sudo contrib/scripts/install_prereq install

# Run the configure script to satisfy build dependencies
sudo ./configure

# Setup menu options by running the following command:
sudo make menuselect.makeopts
sudo menuselect/menuselect --enable app_macro menuselect.makeopts

# (Manual step: Select chan_ooh323, format_mp3, and other options as needed)

# Build Asterisk
sudo make

# Install Asterisk
sudo make install

# Optionally install documentation
# sudo make progdocs

# Install configs and samples
sudo make samples
sudo make config

# Create a separate user and group to run Asterisk services:
sudo groupadd asterisk
sudo useradd -r -d /var/lib/asterisk -g asterisk asterisk
sudo usermod -aG audio,dialout asterisk
sudo chown -R asterisk.asterisk /etc/asterisk
sudo chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
sudo chown -R asterisk.asterisk /usr/lib/asterisk

# Set Asterisk default user to 'asterisk':
# sudo sed -i 's/^AST_USER=.*/AST_USER="asterisk"/' /etc/default/asterisk
# sudo sed -i 's/^AST_GROUP=.*/AST_GROUP="asterisk"/' /etc/default/asterisk

# Configure Asterisk to run as 'asterisk' user and group:
sudo sed -i 's/^runuser=.*/runuser=asterisk/' /etc/asterisk/asterisk.conf
sudo sed -i 's/^rungroup=.*/rungroup=asterisk/' /etc/asterisk/asterisk.conf

# Restart Asterisk service
sudo systemctl restart asterisk

# Enable Asterisk service to start on boot
sudo systemctl enable asterisk

# Test connection to Asterisk CLI
sudo asterisk -rvv

# Open HTTP ports and SIP ports 5060,5061 in UFW firewall
# sudo ufw allow proto tcp from any to any port 5060,5061
