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

# My HCP Boundary instance
provider "boundary" {
  addr                            = var.boundary-address
  auth_method_id                  = "ampw_Sce2pnCbl2"
  auth_method_login_name = "tf-workspace"
  auth_method_password   = data.tfe_outputs.Boundary.values.tf-workspace-pwd 
}

# Get our global network info
data "tfe_outputs" "networks" {
  organization = var.terraform_org
  workspace = "networks-${var.environment}"
}
