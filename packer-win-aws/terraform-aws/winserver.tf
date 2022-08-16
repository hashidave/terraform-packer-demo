#
# EC2 Web Application
#
data "hcp_packer_iteration" "windows" {
  bucket_name = "windows-base"
  channel     = "production"
}

data "hcp_packer_image" "windows_us_east_2" {
  bucket_name    = "windows-base"
  cloud_provider = "aws"
  iteration_id   = data.hcp_packer_iteration.windows.ulid
  region         = "us-east-2"
}

resource "aws_instance" "WinServer" {
  ami                         = data.hcp_packer_image.windows_us_east_2.cloud_image_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.WinServerKeyPair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.WinServer.id
  vpc_security_group_ids      = [aws_security_group.WinServer.id]
  tags = {
    Name = "${var.prefix}- WinTelServer"
  }
}

resource "aws_eip" "WinServer"{
  instance = aws_instance.WinServer.id
  vpc      = true
}

resource "aws_eip_association" "WinServer" {
  instance_id   = aws_instance.WinServer.id
  allocation_id = aws_eip.WinServer.id
}

resource "tls_private_key" "WinServerKey" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
  private_key_filename2 = "${var.prefix}-ssh-key2.pem"
}

resource "aws_key_pair" "WinServerKeyPair" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.WinServerKey.public_key_openssh
}




