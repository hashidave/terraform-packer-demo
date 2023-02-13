#
# Required Providers
#
provider "hcp" {}
provider "vault" {}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner = "Dave"
      Demo       = var.prefix
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
  password_auth_method_password   = data.tfe_outputs.Boundary.values.tf-workspace-pwd 
}


#
# Core AWS Plumbing
#
resource "aws_vpc" "goldenimage" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vpc-${var.region}"
    environment = var.environment
  }
}

resource "aws_subnet" "hashicat" {
  vpc_id     = aws_vpc.goldenimage.id
  cidr_block = var.subnet_prefix

  tags = {
    name = "${var.prefix}-subnet"
  }
}

resource "aws_security_group" "hashicat" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.goldenimage.id

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

  ingress {
    from_port   = 443
    to_port     = 443
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

  tags = {
    Name = "${var.prefix}-security-group"
  }
}

resource "aws_internet_gateway" "goldenimage" {
  vpc_id = aws_vpc.goldenimage.id

  tags = {
    Name = "${var.prefix}-${var.environment}-internet-gateway"
  }
}

resource "aws_route_table" "goldenimage" {
  vpc_id = aws_vpc.goldenimage.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.goldenimage.id
  }
}

resource "aws_route_table_association" "goldenimage" {
  subnet_id      = aws_subnet.hashicat.id
  route_table_id = aws_route_table.goldenimage.id
}
