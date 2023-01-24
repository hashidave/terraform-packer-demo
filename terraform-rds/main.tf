#
# Required Providers
#
provider "hcp" {}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner = "Dave"
      Demo       = "BoundaryRDS"
      Environment = var.environment      
      Rep = "Tim"
    }
  }  
}

# My HCP Boundary instance
provider "boundary" {
  addr                            = var.boundary-address
  auth_method_id                  = "ampw_Sce2pnCbl2"
  password_auth_method_login_name = "tf-workspace"
  password_auth_method_password   = var.TF_WORKSPACE_PWD
}

provider "vault"{
  address = var.vault-cluster
  token=var.VAULT_TOKEN
}

# get info from Vault
#resource "vault_mount" "kvv2" {
#  path        = "kvv2"
#  type        = "kv"
#  options     = { version = "2" }
#  description = "KV Version 2 secret engine mount"
#}



#
# Core AWS Plumbing
#
resource "aws_vpc" "BoundaryRDS" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vpc-${var.region}"
    environment = "production"
  }
}


# RDS Requires subnets in two availability zones
resource "aws_subnet" "BoundaryRDS1" {
  vpc_id     = aws_vpc.BoundaryRDS.id
  cidr_block = var.subnet1_prefix
  availability_zone = var.availability_zone_1
  tags = {
    name = "${var.prefix}-subnet"
  }
}

resource "aws_subnet" "BoundaryRDS2" {
  vpc_id     = aws_vpc.BoundaryRDS.id
  cidr_block = var.subnet2_prefix
  availability_zone = var.availability_zone_2

  tags = {
    name = "${var.prefix}-subnet"
  }
}




resource "aws_security_group" "BoundaryRDS" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.BoundaryRDS.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ingress {
  #  from_port   = 80
  #  to_port     = 80
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  #ingress {
  #  from_port   = 443
  #  to_port     = 443
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-security-group"
  }
}

resource "aws_internet_gateway" "BoundaryRDS" {
  vpc_id = aws_vpc.BoundaryRDS.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_route_table" "BoundaryRDS" {
  vpc_id = aws_vpc.BoundaryRDS.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.BoundaryRDS.id
  }
}

resource "aws_route_table_association" "BoundaryRDS1" {
  subnet_id      = aws_subnet.BoundaryRDS1.id
  route_table_id = aws_route_table.BoundaryRDS.id
}

resource "aws_route_table_association" "BoundaryRDS2" {
  subnet_id      = aws_subnet.BoundaryRDS2.id
  route_table_id = aws_route_table.BoundaryRDS.id
}
