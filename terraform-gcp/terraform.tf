terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.23.1"
    }
    google = {
      source  = "hashicorp/google"
      version = ">3.5.0"
    }
    
  }
  
  
  
  cloud {
    organization = "hashi-DaveR"
    hostname     = "app.terraform.io"

    workspaces {
      name = "packer-terraform-demo"
    }
  }
}

module "network_vpc" {
      source  = "terraform-google-modules/network/google//modules/vpc"
      version = "5.2.0"
      network_name="dave-test-net"
      project_id="{var.gcp_project}"
}
