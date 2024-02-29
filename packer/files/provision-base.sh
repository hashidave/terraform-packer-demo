#!/bin/bash -x

#make sure we're running updated everything
# start with the hashi repo infoformation
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt -y update
# sleep 15

# Install base packages that we need in all builds
#sudo apt -y -f install gpg


# This actually sets the intial password to the value retrieved from vault.
sudo echo "$USER:$UBUNTU_PASSWORD" | sudo chpasswd

#Enable password auth for ssh b/c this is a demo environment & we
#might want to use it
# NOTE: This doesn't seem to be working as of 4/10/23
sudo sed -i 's/PasswordAuthentication\ no/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config

# make vim usable by default
echo "colorscheme delek" >> ~/.vimrc
echo "set number" >> ~/.vimrc


# Clear the history file
history -c

