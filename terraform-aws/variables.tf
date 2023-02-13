##############################################################################
# Variables File
#
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "goldenimage"
}

#Set to dev or production to pull different channels from packer
variable "environment"{
  default = "dev"
}

variable "region" {
  description = "The region where the resources are created."
  default     = "us-east-2"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.10.0/24"
}

variable "instance_type" {
  description = "Specifies the AWS instance type."
  default     = "t2.nano"
}

variable "server_count" {
  description = "Specifies the number of instances to create."
  default     = "1"
}


variable "server2_count" {
  description = "Specifies the number of instances of hashicat2 to create."
  default     = "0"
}


variable "spot_instance_count" {
  description = "Specifies the number of spot instances to create."
  default     = "0"
}

# We should pull this from vault
variable "ssh_private_key" {
  description = "the ssh private key for provisioner"
}

variable "default_username"{
  description = "Don't change this unless you want to do a lot of work"
  default     = "ubuntu"
}


variable "boundary-address"{
  default= "https://868bdfc7-61c6-4f31-b3a0-7bae78941aa0.boundary.hashicorp.cloud"
}


variable "boundary-cluster-id"{
  default="868bdfc7-61c6-4f31-b3a0-7bae78941aa0"
}



variable "VAULT_ADDR" {
  description = "this gets populated from a workspace variable if you used the tfc workspace factory"
 
}

variable "TFC_VAULT_NAMESPACE" {
  description = "this gets populated from a workspace variable"
}


#variable "ubuntu_password" {
#  
#}

