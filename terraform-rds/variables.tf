##############################################################################
# Variables File
#
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "test-rds"
}

variable "terraform-org"{
  default ="hashi-DaveR"
}

variable "Owner" {
  description = "The owner of this project."
  default     = "hashiDaveR"
}



variable "region" {
  description = "The region where the resources are created."
  default     = "us-east-2"
}

#Set to dev or production to pull different channels from packer and deploy from
#different TF workspaces
variable "environment" {
  default = "dev"
}

# We'll get this from the environment.  out bootstrapper will put it there
variable "VAULT_ADDR"{
  default = ""
}


variable "TFC_VAULT_NAMESPACE"{
  default= ""
}

variable "vault_db_mount"{
  default= "rds-demo-db"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "subnet1_prefix" {
  description = "The address prefix to use for the first subnet."
  default     = "10.0.1.0/24"
}

variable "subnet2_prefix" {
  description = "The address prefix to use for the second subnet."
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  description = "The availability zone to use for the first subnet."
  default     = "us-east-2a"
}

variable "availability_zone_2" {
  description = "The availability zone to use for the second subnet."
  default     = "us-east-2b"
}


variable "instance_type" {
  description = "Specifies the AWS instance type."
  default     = "t2.nano"
}


variable "ssh_private_key" {
  description = "the ssh private key for provisioner"
  default     = ""
}

variable "boundary-address"{
  default= "https://868bdfc7-61c6-4f31-b3a0-7bae78941aa0.boundary.hashicorp.cloud"
}

variable "boundary-cluster-id"{
  default="868bdfc7-61c6-4f31-b3a0-7bae78941aa0"
}

# remote workspace where we get some boundary info
# this assumes you have provisioned your overall boundary environment 
# from another workspace
# see https://github.com/hashidave/boundary-dmr which is what this repo
# is dependent on
variable "boundary-parent-workspace"{
  default = "Boundary-Environment-dev"
}

variable boundary_auth_method_id{
  default ="ampw_Sce2pnCbl2"
}


variable "db-count" {
  default = 1
}
