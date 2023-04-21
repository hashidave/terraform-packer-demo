#---------------------------------------------------------------------------------------
# Required Providers
#---------------------------------------------------------------------------------------
provider "google" {
  # credentials = file(var.gcp_credentials)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

provider "hcp" {}
provider "vault" {}


# My HCP Boundary instance
provider "boundary" {
  addr                            = var.boundary-address
  auth_method_id                  = "ampw_Sce2pnCbl2"
  password_auth_method_login_name = "tf-workspace"
  password_auth_method_password   = data.tfe_outputs.Boundary.values.tf-workspace-pwd 
}
