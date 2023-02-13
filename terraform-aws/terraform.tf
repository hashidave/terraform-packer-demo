terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      #version = "0.23.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }

  cloud {
    organization = "hashi-DaveR"
    hostname     = "app.terraform.io"

    workspaces {
      tags = ["goldenimage-aws"]
    }
  }
}



