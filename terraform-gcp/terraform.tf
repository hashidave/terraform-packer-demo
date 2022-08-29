terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.23.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
  
  module "network_vpc" {
    source  = "terraform-google-modules/network/google//modules/vpc"
    version = "5.2.0"
    description "This is my private vpc module"
    network_name="example-vpc"
    project_id={var.gpc_project}
  }

  cloud {
    organization = "hashi-DaveR"
    hostname     = "app.terraform.io"

    workspaces {
      name = "packer-terraform-demo"
    }
  }
}
