terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      #version = "0.23.1"
    }
    google = {
      source  = "hashicorp/google"
      #version = ">3.5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      #version = "4.2.0"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
  
  cloud {
    organization = "hashi-DaveR"
    hostname     = "app.terraform.io"

    workspaces {
      tags = ["terraform-gcp"]
    }
  }
}

