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
  default = "acme-webapp"
}

variable "hcp_bucket_name" {
  default = "acme-webapp"
}

# specify the channel name from whence to pull the base image.
variable "base-image-channel"{
}


variable "version" {
  default = "2.0.2"
}


variable "hcp_bucket_name_base" {
  default = "acme-base"
}


#--------------------------------------------------
# HCP Packer Registry
# - Base Image Bucket and Channel
#--------------------------------------------------
# Returh the most recent Iteration (or build) of an image, given a Channel
data "hcp-packer-iteration" "acme-base" {
  bucket_name = var.hcp_bucket_name_base
  channel     = var.base-image-channel
}


#--------------------------------------------------
# AWS Image Config and Definition
#--------------------------------------------------
variable "aws_region" {
  default = "us-east-2"
}

data "hcp-packer-image" "aws" {
  cloud_provider = "aws"
  region         = var.aws_region
  bucket_name    = var.hcp_bucket_name_base
  iteration_id   = data.hcp-packer-iteration.acme-base.id
}

source "amazon-ebs" "acme-webapp" {
  region         = var.aws_region
  source_ami     = data.hcp-packer-image.aws.id
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
    description = "The HashiCat Web Server"
 
    bucket_labels = {
      "owner"          = "application-team"
      "os"             = "Ubuntu"
      "ubuntu-version" = "Focal 20.04"
      "image-name"     = var.image_name
    }

    build_labels = {
      "build-time"        = timestamp()
      "build-source"      = basename(path.cwd)
      "acme-base-version" = data.hcp-packer-image.aws.labels.acme-base-version
      "acme-app-version"  = var.version
    }
  }

  sources = [
    "source.amazon-ebs.acme-webapp"
  ]

  provisioner "file" {
    source      = "files/deploy-app.sh"
    destination = "/tmp/deploy-app.sh"
  }
  
  provisioner "file" {
    source      = "files/deploy-app2.sh"
    destination = "/home/ubuntu/deploy-app2.sh"
  }
  
  provisioner "shell" {
    inline = ["bash /tmp/deploy-app.sh"]
  }

}
