
#!/bin/bash
#########
####  Gets the bits for boundary & writes a stub config file that will be altered 
####  when Terraform deploys the actual system


#Get the boundary worker binary & install
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install boundary-worker-hcp

# cleanup boundary service file
sudo sed -i 's/boundary server/boundary-worker server/g' /usr/lib/systemd/system/boundary.service
sudo sed -i 's/\%i/boundary/g' /usr/lib/systemd/system/boundary.service
sudo mkdir /opt/boundary
sudo chown boundary:boundary /opt/boundary
sudo chmod 2700 /opt/boundary
sudo systemctl daemon-reload
sudo systemctl enable boundary



# Create a baseline config
sudo cat << EOF > ~/pki-worker.hcl
disable_mlock = true

hcp_boundary_cluster_id = "CLUSTER_ID_HERE"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr = "<worker_public_addr>"
  auth_storage_path = "/home/ubuntu/boundary/worker1"
  tags {
    type = ["worker", "dev"]
  }
  
  controller_generated_activation_token="CONTROLLER_GENERATED_TOKEN_HERE"

}
EOF

sudo mv ~/pki-worker.hcl /etc/boundary.d


#Terraform provisioner will replace the cluster_id and controller_generated_token bits at deployment