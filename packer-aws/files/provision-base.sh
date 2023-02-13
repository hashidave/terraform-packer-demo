#!/bin/bash -x


#make sure we're running updated everything
sudo apt -y update
# sleep 15

# Install base packages that we need in all builds
#sudo apt -y -f install gpg

sudo echo "$USER:$UBUNTU_PASSWORD" | sudo chpasswd

#Enable password auth for ssh b/c this is a demo environment & we
#might want to use it
sudo sed -i 's/PasswordAuthentication\ no/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config

# Clear the history file
history -c

