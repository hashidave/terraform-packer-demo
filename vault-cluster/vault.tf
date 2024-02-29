#
# EC2 Vault Instance
#


data "aws_iam_policy_document" "vault-server-policy" {
  statement {
    effect = "Allow"

   #principals {
   #   type        = "Service"
   #   identifiers = ["ec2.amazonaws.com"]
   # }
    resources = ["*"]
    actions = ["ec2:DescribeInstances"]
  }
}

resource "aws_iam_role" "vault-server-role" {
  name               = "vault_server_role"
  #path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
      "Service": "ec2.amazonaws.com"
      },        
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "vault-join-policy" {
  name        = "${var.prefix}-vault-join"
  description = "Allows Vault nodes to describe instances for joining."
  policy      = data.aws_iam_policy_document.vault-server-policy.json
}

resource "aws_iam_policy_attachment" "vault-join" {
  name       = "${var.prefix}-vault-join"
  roles      = [aws_iam_role.vault-server-role.name]
  policy_arn = aws_iam_policy.vault-join-policy.arn
}

resource "aws_iam_instance_profile" "vault-server-profile" {
  name = "vault_server_profile"
  role = aws_iam_role.vault-server-role.name
}


resource "aws_security_group" "vault-security-group" {
  name = "${var.prefix}-default-security-group"

  vpc_id = data.tfe_outputs.networks.values.vpc

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
    cidr_blocks = [data.tfe_outputs.networks.values.general-subnet.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.tfe_outputs.networks.values.general-subnet.cidr_block]
  }

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [data.tfe_outputs.networks.values.general-subnet.cidr_block]
  }

  ingress {
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = [data.tfe_outputs.networks.values.general-subnet.cidr_block]
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-default-security-group"
  }
}

data "hcp_packer_artifact" "ubuntu_us_east_2" {
  bucket_name    = "acme-vault-server"
  channel_name = var.environment
  platform = "aws"
  region         = var.region
}



resource "aws_instance" "vault" {
  count                       = var.server_count
  ami                         = data.hcp_packer_artifact.ubuntu_us_east_2.external_identifier
  instance_type               = var.instance_type
  key_name                    = "DaveTestKey-Ohio"
  associate_public_ip_address = true
  subnet_id                   = data.tfe_outputs.networks.values.general-subnet.id
  vpc_security_group_ids      = [aws_security_group.vault-security-group.id]
  iam_instance_profile        = aws_iam_instance_profile.vault-server-profile.name

  tags = {
    Type="Vault", 
    Name = "${var.prefix}-HashiCorpVault",
    "${var.prefix}-${var.environment}" = "server"
  }

  
}

resource "terraform_data" "vault-provisioner" {
    count = var.server_count
    #triggers_replace=[
      #aws_instance.boundary-worker,
    #  aws_eip.boundary-worker.id, 
    #  boundary_worker.private-worker.id
    #]   
 
    #depends_on = [
    #     #aws_instance.boundary-worker,
    #     boundary_worker.private-worker,
    #     aws_eip.boundary-worker
    #]


    connection {
       type     = "ssh"
       user     = "ubuntu"
       host     = aws_eip.vault[count.index].public_ip
       port     = 22
       private_key = var.ssh_private_key
     }
  
  provisioner "remote-exec" {
    inline=[
      #"sudo echo '${var.default_username}:${random_password.user-password.result}' | sudo chpasswd",
      "sudo sed -i ''s/##TAG_HERE##/${var.prefix}-${var.environment}/g'' /etc/vault.d/vault.hcl",
      "sudo sed -i ''s/##REGION_HERE##/${var.region}/g'' /etc/vault.d/vault.hcl",
      "sudo sed -i ''s/##CLUSTER_ADDR_HERE##/${aws_eip.vault[count.index].public_dns}/g'' /etc/vault.d/vault.hcl",
      "sudo sed -i ''s/##API_ADDR_HERE##/${aws_instance.vault[count.index].private_dns}/g'' /etc/vault.d/vault.hcl",
      "sudo service vault --full-restart"
     ]
  }
}

resource "aws_eip" "vault" {
  count = var.server_count
  instance = aws_instance.vault[count.index].id
  domain      = "vpc"
}

resource "aws_eip_association" "vault" {
  count=var.server_count
  instance_id   = aws_instance.vault[count.index].id
  allocation_id = aws_eip.vault[count.index].id
}





#### Provision some default secrets into vault


# Generate a random password for our user
resource "random_password" "user-password" {
  length           = 16
  special          = true
  override_special = "+_-"
}



