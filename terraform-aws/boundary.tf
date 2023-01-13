# Get the project ID from the main boundary project
data "tfe_outputs" "Boundary" {
  organization = "hashi-DaveR"
  workspace = "Boundary-Environment"
}


resource "boundary_host_set_plugin" "host_set" {
  name            = "GoldenImage AWS Dev Host Set"
  host_catalog_id = data.tfe_outputs.Boundary.nonsensitive_values.host_catalog
  attributes_json = jsonencode({ "filters" = "tag:host-set=DMR_GOLDEN_IMAGE_AWS_DEV" })

  # Have to set the endpoints to whatever IP Addresses that AWS asssigns
  preferred_endpoints=formatlist("cidr:%s/32", aws_eip.hashicat.*.public_ip)

}

# Create a controller-lead HCP Boundary Worker Object
resource "boundary_worker" "private-worker"{
  scope_id    = var.BoundaryProject
  description = "Golden Image Workflow Worker"
  name        = "goldenimageworker"
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

    connection {
       type     = "ssh"
       user     = "ubuntu"
       host     = self.public_ip
       port     = 22
       private_key = var.ssh_private_key
     }


     #Provisioner will fill out the stub config file with some important 
     #Boundary info & restart the boundary-worker service
     provisioner "remote-exec" {
       inline=[
         "sudo sed -i ''s/CONTROLLER_GENERATED_TOKEN_HERE/${boundary_worker.private-worker.controller_generated_activation_token}/g'' /etc/boundary.d/pki-worker.hcl"
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


