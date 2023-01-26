#--------------------------------------------------
# Packer Plugins
#--------------------------------------------------
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

#--------------------------------------------------
# Common Image Metadata
#--------------------------------------------------
variable "hcp_bucket_name" {
  default = "acme-base"
}

variable "image_name" {
  default = "acme-base"
}

variable "version" {
  default = "2.0.0"
}


#--------------------------------------------------
# AWS Image Config and Definition
#--------------------------------------------------
variable "aws_region" {
  default = "us-east-2"
}

data "amazon-ami" "aws_base" {
  region = var.aws_region
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "acme-base" {
  region         = var.aws_region
  source_ami     = data.amazon-ami.aws_base.id
  instance_type  = "t2.micro"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "packer_aws_{{timestamp}}_${var.image_name}_v${var.version}"
}

# Vault Connection so we can get some secrets
local "UbuntuPassword"{
  expression =  vault ("kv/data/ubuntu-user", "password")
  sensitive = true
}


#--------------------------------------------------
# Common Build Definition
#--------------------------------------------------
build {

  hcp_packer_registry {
    bucket_name = var.hcp_bucket_name
    description = "Base Ubuntu Image for Dave's Factory" 
    
    bucket_labels = {
      "owner"          = "platform-team"
      "os"             = "Ubuntu"
      "ubuntu-version" = "Focal 20.04"
      "image-name"     = var.image_name
    }

    build_labels = {
      "build-time"        = timestamp()
      "build-source"      = basename(path.cwd)
      "acme-base-version" = var.version
    }
  }

  sources = [
    "source.amazon-ebs.acme-base"
  ]

  provisioner "file" {
    source      = "files/provision-base.sh"
    destination = "/home/ubuntu/provision-base.sh"
  }

  # move the dave user public key
  provisioner "file" {
    source      = "files/authorized_keys"
    destination = "/home/ubuntu/authorized_keys"
  }



  provisioner "shell" {
    script= "files/provision-base.sh"
    environment_vars= ["UBUNTU_PASSWORD=${local.UbuntuPassword}"]
             
  }
}
