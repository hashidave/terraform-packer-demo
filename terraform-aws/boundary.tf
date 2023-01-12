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


resource "aws_eip" "boundary-worker" {
  instance = aws_instance.boundary-worker.id
  vpc      = true
}

resource "aws_eip_association" "boundary-worker" {
  instance_id   = aws_instance.boundary-worker.id
  allocation_id = aws_eip.boundary-worker.id
}



resource "aws_security_group" "boundary-worker" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.hashicat.id

  ingress {
    from_port   = 443
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


