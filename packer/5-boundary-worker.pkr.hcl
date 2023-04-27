#------------------------------------------------
# Packer Plugins
#--------------------------------------------------
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/amazon"
    }
    googlecompute = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}


#--------------------------------------------------
# Common Image Metadata
#--------------------------------------------------
variable "image_name" {
  default = "boundary-worker"
}

variable "hcp_bucket_name" {
  default = "boundary-workers"
}

variable "version" {
  default = "3.0.0"
}

#The channel from whence to pull the base image
variable "base-image-channel" {
  default= "production"
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

data "hcp-packer-image" "aws_base" {
  cloud_provider = "aws"
  region         = var.aws_region
  bucket_name    = var.hcp_bucket_name_base
  iteration_id   = data.hcp-packer-iteration.acme-base.id
}

source "amazon-ebs" "aws_base" {
  region         = var.aws_region
  source_ami     = data.hcp-packer-image.aws_base.id
  instance_type  = "t2.nano"
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
    description = "Boundary Worker Image. Contains HCP Boundary Worker package"
    bucket_labels = {
      "owner"          = "application-team"
      "os"             = "Ubuntu"
      "ubuntu-version" = "Focal 20.04"
      "image-name"     = var.image_name
    }

    build_labels = {
      "build-time"        = timestamp()
      "build-source"      = basename(path.cwd)
      "acme-base-version" = data.hcp-packer-image.aws_base.labels.acme-base-version
      "acme-app-version"  = var.version
    }
  }

  sources = [
    "source.amazon-ebs.aws_base"
  ]

  provisioner "file" {
     source      = "files/deploy-worker.sh"
     destination = "/home/ubuntu/deploy-worker.sh"
  }

  provisioner "shell" {
     inline = ["bash /home/ubuntu/deploy-worker.sh"                                     
  
     ]
   }
}
