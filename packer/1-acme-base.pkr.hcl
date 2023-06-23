#--------------------------------------------------
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
variable "hcp_bucket_name" {
  default = "acme-base"
}

variable "image_name" {
  default = "acme-base"
}

variable "version" {
  default = "3.0.0"
}

variable "default_username"{
  default="ubuntu"
}

variable default_user_password_path{
  # Where in vault to get the initial password for our user.  
  # Should contain a key called "password"
  # The terraform-aws repo will reset this when it gets deployed
  default="kv/data/ubuntu-user"
}


#--------------------------------------------------
# AWS Image Config and Definition
#--------------------------------------------------
variable "aws_region" {
  default = "us-east-2"
}

# Metadata for the vanilla ubuntu image
data "amazon-ami" "aws_base" {
  region = var.aws_region
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

# Instantiate a new ec2 from the ubuntu image above.
source "amazon-ebs" "acme-base" {
  region         = var.aws_region
  source_ami     = data.amazon-ami.aws_base.id
  instance_type  = "t2.nano"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "packer_aws_{{timestamp}}_${var.image_name}_v${var.version}"
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

variable "gce_source_image" {
  default = "ubuntu-2004-focal-v20220615"
}

# Instantiate a googlecompute instance based on metadata above
source "googlecompute" "google-base" {
  project_id   = var.gcp_project
  source_image = var.gce_source_image
  zone         = var.gce_zone
  #instance_type="e2.micro"
  # The AWS Ubuntu image uses user "ubuntu", so we shall do the same here
  ssh_username = "ubuntu"
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
    "source.amazon-ebs.acme-base",
    "source.googlecompute.google-base"
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
