#
# EC2 Web Application
#
data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "acme-webapp"
  channel     = "production"
}

data "hcp_packer_image" "ubuntu_us_east_2" {
  bucket_name    = "acme-webapp"
  cloud_provider = "aws"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = "us-east-2"
}

resource "aws_instance" "hashicat" {
  ami                         = data.hcp_packer_image.ubuntu_us_east_2.cloud_image_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.hashicat.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.hashicat.id
  vpc_security_group_ids      = [aws_security_group.hashicat.id]
  count =2
  tags = {
    "web-server", 
    "lunch", "butters", 
    Name = "${var.prefix}-HashiCat-Web-App"
  }
}

resource "aws_eip" "hashicat" {
  count = 2
  instance = aws_instance.hashicat[count.index].id
  vpc      = true
}

resource "aws_eip_association" "hashicat" {
  count=2 
  instance_id   = aws_instance.hashicat[count.index].id
  allocation_id = aws_eip.hashicat[count.index].id
}

resource "tls_private_key" "hashicat" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
  private_key_filename2 = "${var.prefix}-ssh-key2.pem"
}

resource "aws_key_pair" "hashicat" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.hashicat.public_key_openssh
}



resource "aws_instance" "hashicat2" {
  ami                         = data.hcp_packer_image.ubuntu_us_east_2.cloud_image_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.hashicat2.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.hashicat.id
  vpc_security_group_ids      = [aws_security_group.hashicat.id]

  tags = {
    Name = "${var.prefix}-HashiCat-Web-App2"
  }


  connection {
    type     = "ssh"
    user     = "ubuntu"
    host     = self.public_ip 
    port     = 22
    private_key = tls_private_key.hashicat2.private_key_openssh
  }

  provisioner "remote-exec" {
    inline=[
      "bash /home/ubuntu/deploy-app2.sh"
    ]
  }
}

resource "aws_eip" "hashicat2" {
  instance = aws_instance.hashicat2.id
  vpc      = true
}

resource "aws_eip_association" "hashicat2" {
  instance_id   = aws_instance.hashicat2.id
  allocation_id = aws_eip.hashicat2.id
}

resource "tls_private_key" "hashicat2" {
  algorithm = "RSA"
}

resource "aws_key_pair" "hashicat2" {
  key_name   = local.private_key_filename2
  public_key = tls_private_key.hashicat2.public_key_openssh
}

resource "aws_spot_instance_request" "hashicat_spot" {
  ami                         = data.hcp_packer_image.ubuntu_us_east_2.cloud_image_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.hashicat2.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.hashicat.id
  vpc_security_group_ids      = [aws_security_group.hashicat.id]
  
  #spot instance info
  spot_price = "0.01"
  wait_for_fulfillment = true

  tags = {
    Name = "${var.prefix}-HashiCat-Web-App_Spot"
  }


  connection {
    type     = "ssh"
    user     = "ubuntu"
    host     = self.public_ip 
    port     = 22
    private_key = tls_private_key.hashicat2.private_key_openssh
  }

  provisioner "remote-exec" {
    inline=[
      "bash /home/ubuntu/deploy-app2.sh"
    ]
  }
}

resource "aws_eip" "hashicat_spot" {
  instance = aws_spot_instance_request.hashicat_spot.spot_instance_id
  vpc      = true
}

resource "aws_eip_association" "hashicat_spot" {
  instance_id   = aws_spot_instance_request.hashicat_spot.spot_instance_id
  allocation_id = aws_eip.hashicat_spot.id
}



