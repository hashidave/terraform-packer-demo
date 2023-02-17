#!/bin/bash -x

#make sure we're running updated everything
# start with the hashi repo infoformation
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

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

