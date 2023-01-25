##############################################################################
# Variables File
#
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "boundary-rds"
}

#Set to dev or production to pull different channels from packer and deploy from
#different TF workspaces
variable "environment"{
  default = "dev"
}


variable "vault-cluster"{
  default = "https://hashiDaveR-vault-cluster-public-vault-f886c6aa.441332cd.z1.hashicorp.cloud:8200"
}


# The main token that TF uses to obtain secrets
variable "VAULT_TOKEN" {
  default=""
}

# This is the token we hand off to boundary for future use.
# in a future rev we'll make this dynamically generated in the run & get rid of this.
variable "BOUNDARY_VAULT_TOKEN" {
  default=""
}

variable "region" {
  description = "The region where the resources are created."
  default     = "us-east-2"
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

variable "boundary-project"{
  default="p_t0BBolQK8o"
}

# used to construct the host filter for a host set of this workspace's hosts
variable "boundary-host-set-base-tag"{
  default="BOUNDARY_RDS"
}

variable login_approle_role_id {
  default="52d0945b-e373-bd3f-49bf-2ba5b84b548e"
} 

variable VAULT_SECRET {
  default="xxxx"
}

variable "TF_WORKSPACE_PWD" {
 description = "boundary user password"
 default     = ""
}

variable "ubuntu_password" {
  default = ""
}

