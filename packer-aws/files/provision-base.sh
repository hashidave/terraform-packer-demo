#!/bin/bash -x


#make sure we're running updated everything
sudo apt -y update
# sleep 15

# Install base packages that we need in all builds
#sudo apt -y -f install gpg

# add our regular user account w/password from vault
#sudo useradd -m -d /home/dave -p $(echo ${var.UbuntuPassword} | openssl passwd -1 -stdin) dave
sudo useradd -m -d /home/dave -p $(echo $UBUNTU_PASSWORD | openssl passwd -1 -stdin) dave

sudo mkdir /home/dave/.ssh

#Set dave up for key-based login
sudo mv /home/ubuntu/authorized_keys /home/dave/.ssh/authorized_keys
sudo chmod -R go= /home/dave/.ssh
sudo chown -R dave.dave /home/dave


#Enable password auth for ssh b/c this is a demo environment & we
#might want to use it
sudo sed -i 's/PasswordAuthentication\ no/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config

# Clear the history file
history -c

