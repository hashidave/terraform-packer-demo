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
  default = "acme-webapp"
}

variable "hcp_bucket_name" {
  default = "acme-webapp"
}

# specify the channel name from whence to pull the base image.
variable "base-image-channel"{
  default = "production"
}


variable "version" {
  default = "3.0.0"
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

#-------------------------
# GCP Information
#-------------------------
variable "gcp_project" {
  default = "mystical-glass-360520"
}

variable "gce_region" {
  default = "us-central1"
}

variable "gce_zone" {
  default = "us-central1-c"
}

# Retrieve Latest Iteration ID for packer-terraform-demo/gce
data "hcp-packer-image" "gce" {
  cloud_provider = "gce"
  # The key is named "region", but in GCE it actually wants the "zone"
  region       = var.gce_zone
  bucket_name  = var.hcp_bucket_name_base
  iteration_id = data.hcp-packer-iteration.acme-base.id
}

source "googlecompute" "acme-webapp" {
  project_id   = var.gcp_project
  source_image = data.hcp-packer-image.gce.id
  zone         = var.gce_zone
  # The AWS Ubuntu image uses user "ubuntu", so we shall do the same here
  ssh_username = "ubuntu"
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
    "source.amazon-ebs.acme-webapp",
     "source.googlecompute.acme-webapp"
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
