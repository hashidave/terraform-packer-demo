
#!/bin/bash
#########
####  Gets the bits for boundary & writes a stub config file that will be altered 
####  when Terraform deploys the actual system
sudo apt-get update && sudo apt-get install boundary-worker-hcp

sudo service boundary stop
sudo rm -rf /opt/boundary

# cleanup boundary service file
sudo sed -i 's/boundary server/boundary-worker server/g' /usr/lib/systemd/system/boundary.service
sudo sed -i 's/%i/boundary/g' /usr/lib/systemd/system/boundary.service
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
  public_addr = "WORKER_PUBLIC_IP_HERE"
  auth_storage_path = "/opt/boundary/worker1"
  tags {
    type      = ["worker"]
    env       = ["ENVIRONMENT_TAG_HERE"]
    project   = ["PROJECT_TAG_HERE"]
  }
  
  controller_generated_activation_token="CONTROLLER_GENERATED_TOKEN_HERE"

}
EOF

sudo chmod 755 ~/pki-worker.hcl

# we always want to have a copy of this so we can replace
# the config if something gets redeployed
sudo cp ~/pki-worker.hcl /etc/boundary.d/boundary.hcl


#Terraform provisioner will replace the XXX_HERE bits at deployment
