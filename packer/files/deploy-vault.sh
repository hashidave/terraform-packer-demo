#!/bin/bash

# install vault & move the config files to the right place
sudo apt-get update && sudo apt-get dist-upgrade
sudo apt-get install vault-enterprise

sudo mv /tmp/license.hclic /etc/vault.d/license.hclic

# Store a copy of the config template so we don't lose it
cp /tmp/vault.hcl ~
sudo cp /tmp/vault.hcl /etc/vault.d


echo "export VAULT_ADDR=http://127.0.0.1:8200" >> ~/.bashrc

echo "deploy-vault.sh Script Complete."


