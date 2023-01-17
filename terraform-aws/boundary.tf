# Get the project ID from the main boundary project
data "tfe_outputs" "Boundary" {
  organization = "hashi-DaveR"
  workspace = "Boundary-Environment"
}


resource "boundary_host_set_plugin" "host_set" {
  name            = "GoldenImage AWS Dev Host Set"
 
  # The host catalog comes from an external state for our general boundary environment
  host_catalog_id = data.tfe_outputs.Boundary.nonsensitive_values.host_catalog
  attributes_json = jsonencode({ "filters" = "tag:host-set=DMR_GOLDEN_IMAGE_AWS_DEV" })

  # Have to set the endpoints to whatever IP Addresses that AWS asssigns
  preferred_endpoints=["cidr:${var.subnet_prefix}"]

}

resource "boundary_credential_store_vault" "vault-store" {
  name        = "vault-store"
  description = "Demo connection to my HCP Vault"
  address     = var.vault-cluster
  token       = var.vault-token 
  scope_id    = var.boundary-project
}

resource "boundary_credential_library_vault" "vault-library" {
  name                = "hcp-vault-library"
  description         = "HCP Vault credential library"
  credential_store_id = boundary_credential_store_vault.vault-store.id
  credential_type     = "username_password"
  path                = "kv/data/GoldenImageDev/pasword" # change to Vault backend path
  http_method         = "GET"
}


resource "boundary_target" "server-ssh" {
  name         = "server-ssh"
  description  = "ssh target"
  type         = "tcp"
  default_port = "22"
  scope_id     = var.boundary-project
  host_source_ids = [
    boundary_host_set_plugin.host_set.id
  ]
  brokered_credential_source_ids = [
  
  ]
}


# Create a controller-lead HCP Boundary Worker Object
resource "boundary_worker" "private-worker"{
  scope_id    = "global" 
  description = "Golden Image Workflow Worker"
  name        = "goldenimageworker"

  # The activation token on the HCP side is only good for one run so if we
  # change the worker ec2 instance for any reason we have to re-create the HCP boundary_worker
  lifecycle{
     # ARRRRG this creates a circlar dependency!!
     replace_triggered_by=[aws_instance.boundary-worker]
  }


}



# Deploy a boundary worker into our environment
  data "hcp_packer_iteration" "boundary-worker" {
    bucket_name = "boundary-workers"
    channel     = "production"
  } 
 
  data "hcp_packer_image" "boundary-worker" {
    bucket_name    = "boundary-workers"
    cloud_provider = "aws"
    iteration_id   = data.hcp_packer_iteration.boundary-worker.ulid
    region         = var.region
  }
 
  resource "aws_instance" "boundary-worker" {
    ami                         = data.hcp_packer_image.boundary-worker.cloud_image_id
    instance_type               = var.instance_type
    key_name                    = "DaveTestKey-Ohio"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.hashicat.id
    vpc_security_group_ids      = [aws_security_group.boundary-worker.id]
   
    tags = {
      Type="Boundary_Worker",
      Name = "${var.prefix}-BoundaryWorker",
    }

  }



  # This exist only to get around the circular dependency between the worker & the aws_eip
  # that we have to put into the config file.
  resource "null_resource" "worker-provisioner" {
    triggers={
      worker-id=aws_instance.boundary-worker.id,
      worker-ip=aws_eip.boundary-worker.public_ip
    }
       

    connection {
       type     = "ssh"
       user     = "ubuntu"
       host     = aws_eip.boundary-worker.public_ip
       port     = 22
       private_key = var.ssh_private_key
     }


     #Provisioner will fill out the stub config file with some important 
     #Boundary info & restart the boundary-worker service
     provisioner "remote-exec" {
       inline=[
         "sudo sed -i ''s/CLUSTER_ID_HERE/${var.boundary-cluster-id}/g'' /etc/boundary.d/boundary.hcl",
	
         "sudo sed -i ''s/CONTROLLER_GENERATED_TOKEN_HERE/${boundary_worker.private-worker.controller_generated_activation_token}/g'' /etc/boundary.d/boundary.hcl",
         "sudo sed -i ''s/WORKER_PUBLIC_IP_HERE/${aws_eip.boundary-worker.public_ip}/g'' /etc/boundary.d/boundary.hcl",
	"sudo service boundary --full-restart"
       ]
     }
 }


resource "aws_eip" "boundary-worker" {
  instance = aws_instance.boundary-worker.id
  vpc      = true
}

resource "aws_eip_association" "boundary-worker" {
  instance_id   = aws_instance.boundary-worker.id
  allocation_id = aws_eip.boundary-worker.id
}



resource "aws_security_group" "boundary-worker" {
  name = "boundary-worker-security-group"

  vpc_id = aws_vpc.hashicat.id
ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9202
    to_port     = 9202
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
}


