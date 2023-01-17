#
# Required Providers
#
provider "hcp" {}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner = "Dave"
      Demo       = "GoldenImage"
      Dev = "True"
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

#provider "vault"{
#  address = "https://hashiDaveR-vault-cluster-public-vault-f886c6aa.441332cd.z1.hashicorp.cloud:8200"
#  auth_login{
#    path="auth/approle/login"
#    parameters={
#      role_id=var.login_approle_role_id
#      secret_id=var.VAULT_SECRET
#    }
#  }  
#}

# get info from Vault
#resource "vault_mount" "kvv2" {
#  path        = "kvv2"
#  type        = "kv"
#  options     = { version = "2" }
#  description = "KV Version 2 secret engine mount"
#}

# data "vault_generic_secret" "linux-creds" {
#   path  = "kv/GoldenImageDev"
# }



#
# Core AWS Plumbing
#
resource "aws_vpc" "hashicat" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vpc-${var.region}"
    environment = "production"
  }
}

resource "aws_subnet" "hashicat" {
  vpc_id     = aws_vpc.hashicat.id
  cidr_block = var.subnet_prefix

  tags = {
    name = "${var.prefix}-subnet"
  }
}

resource "aws_security_group" "hashicat" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.hashicat.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_internet_gateway" "hashicat" {
  vpc_id = aws_vpc.hashicat.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_route_table" "hashicat" {
  vpc_id = aws_vpc.hashicat.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hashicat.id
  }
}

resource "aws_route_table_association" "hashicat" {
  subnet_id      = aws_subnet.hashicat.id
  route_table_id = aws_route_table.hashicat.id
}
