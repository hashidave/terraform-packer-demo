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

variable "default_username"{
  default="ubuntu"
}

variable default_user_password_path{
  # Where in vault to get the initial password for our user.  
  # Should contain a key called "password"
  # The terraform-aws repo will reset this...
  default="kv/data/ubuntu-user"
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
  instance_type  = "t2.nano"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "packer_aws_{{timestamp}}_${var.image_name}_v${var.version}"
}

# Vault Connection so we can get some secrets
local "UbuntuPassword" {
  expression =  vault (var.default_user_password_path, "password")
  sensitive = true
}


#--------------------------------------------------
# Common Build Definition
#--------------------------------------------------
build {

  hcp_packer_registry {
    bucket_name = var.hcp_bucket_name
    description = "Base Ubuntu Image for ${var.default_username}'s Factory" 
    
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

  provisioner "shell" {
    script= "files/provision-base.sh"
    environment_vars= ["USER=${var.default_username}", "UBUNTU_PASSWORD=${local.UbuntuPassword}",]
         
  }
}
