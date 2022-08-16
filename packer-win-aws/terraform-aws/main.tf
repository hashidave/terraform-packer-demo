#
# Required Providers
#
provider "hcp" {}

provider "aws" {
  region = var.region
}

#
# Core AWS Plumbing
#
resource "aws_vpc" "WinServer" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vpc-${var.region}"
    environment = "production"
  }
}

resource "aws_subnet" "WinServer" {
  vpc_id     = aws_vpc.WinServer.id
  cidr_block = var.subnet_prefix

  tags = {
    name = "${var.prefix}-subnet"
  }
}

resource "aws_security_group" "WinServer" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.WinServer.id

  ingress {
    from_port   = 3389 
    to_port     = 3389
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

resource "aws_internet_gateway" "WinServer" {
  vpc_id = aws_vpc.WinServer.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_route_table" "WinServer" {
  vpc_id = aws_vpc.WinServer.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.WinServer.id
  }
}

resource "aws_route_table_association" "WinServer" {
  subnet_id      = aws_subnet.WinServer.id
  route_table_id = aws_route_table.WinServer.id
}
