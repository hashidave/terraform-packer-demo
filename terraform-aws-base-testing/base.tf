#
# EC2 Web Application
#
data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "acme-base"
  channel     = "dev"
}

data "hcp_packer_image" "ubuntu_us_east_2" {
  bucket_name    = "acme-base"
  cloud_provider = "aws"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = var.region
}

resource "aws_instance" "base-test" {
  ami                         = data.hcp_packer_image.ubuntu_us_east_2.cloud_image_id
  instance_type               = var.instance_type
  key_name                    = "DaveTestKey-Ohio"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.base-test.id
  vpc_security_group_ids      = [aws_security_group.base-test.id]
  tags = {
    Type="base-testing", 
    Name = "${var.prefix}-base-test",
  }
}

resource "aws_eip" "base-test" {
  instance = aws_instance.base-test.id
  vpc      = true
}

resource "aws_eip_association" "base-test" {
  instance_id   = aws_instance.base-test.id
  allocation_id = aws_eip.base-test.id
}
