#
# Required Providers
#
provider "hcp" {}
provider "vault" {}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Owner = "Dave"
      Demo       = var.prefix
      Environment = var.environment      
      Rep = "Tim"
    }
  }  
}



# Get our global network info
data "tfe_outputs" "networks" {
  organization = var.terraform_org
  workspace = "networks-${var.environment}"
}
