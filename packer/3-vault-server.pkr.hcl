#------------------------------------------------
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
variable "image_name" {
  default = "acme-vault-server"
}

variable "hcp_bucket_name" {
  default = "acme-vault-server"
}

# specify the channel name from whence to pull the base image.
variable "base-image-channel"{
  default = "production"
}


variable "version" {
  default = "1.0.0"
}


variable "hcp_bucket_name_base" {
  default = "acme-base"
}


#--------------------------------------------------
# HCP Packer Registry
# - Base Image Bucket and Channel
#--------------------------------------------------
# Returh the most recent Iteration (or build) of an image, given a Channel
#data "hcp-packer-version" "acme-base" {
#  bucket_name  = var.hcp_bucket_name_base
#  channel_name = var.base-image-channel
#}


#--------------------------------------------------
# AWS Image Config and Definition
#--------------------------------------------------
variable "aws_region" {
  default = "us-east-2"
}

data "hcp-packer-artifact" "aws" {
  bucket_name    = var.hcp_bucket_name_base
  platform       = "aws"
  channel_name   = "production"
  region         = var.aws_region
  #iteration_id   = data.hcp-packer-version.acme-base.id
}

source "amazon-ebs" "acme-base" {
  region         = var.aws_region
  source_ami     = data.hcp-packer-artifact.aws.external_identifier
  instance_type  = "t2.small"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "packer_aws_{{timestamp}}_${var.image_name}v${var.version}"
} 



#--------------------------------------------------
# Common Build Definition
#--------------------------------------------------
# Version 1 website 
build {

  hcp_packer_registry {
    bucket_name = var.hcp_bucket_name
    description = "HashiCorp Vault Server"
 
    bucket_labels = {
      "owner"          = "InfoSec"
      "os"             = "Ubuntu"
      "ubuntu-version" = "Focal 20.04"
      "image-name"     = var.image_name
    }

    build_labels = {
      "build-time"        = timestamp()
      "build-source"      = basename(path.cwd)
      #"acme-base-version" = data.hcp-packer-artifact.aws.labels.acme-base-version
      "acme-vault-version"  = var.version
    }
  }

  sources = [
    "source.amazon-ebs.acme-base",
   ]

  # Load the config shell script to the image
  provisioner "file" {
    source      = "files/deploy-vault.sh"
    destination = "/tmp/deploy-vault.sh"
  }

 # Load the vault config file
  provisioner "file" {
    source      = "files/vault.hcl"
    destination = "/tmp/vault.hcl"
  }

   
  # Load the vault license file
  provisioner "file" {
    source      = "/etc/vault.d/license.hclic"
    destination = "/tmp/license.hclic"
  }

  
  # and run the script
  provisioner "shell" {
    inline = ["bash /tmp/deploy-vault.sh"]
  }

}
