terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      #version = "0.23.1"
    }
    aws = {
      source  = "hashicorp/aws"
      #version = "4.2.0"
    }
    vault = {
      #version = "~> 3.12.0"
    }
    boundary ={
      #version = "1.1.3"
    }
  }

  cloud {
    organization = "hashi-DaveR"
    hostname     = "app.terraform.io"

    workspaces {
      tags = ["terraform-rds"]
    }
  }
}



