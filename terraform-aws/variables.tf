##############################################################################
# Variables File
#
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "hashicat-demo"
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
  default     = "2"
}


variable "spot_instance_count" {
  description = "Specifies the number of spot instances to create."
  default     = "0"
}

variable "ssh_private_key" {
  description = "the ssh private key for provisioner"
  default     = ""
}

variable "BoundaryProject"{
  description = "The Scope ID for the SE Demos Project"
  default     = "global"
}

variable "TF_WORKSPACE_PWD" {
 description = "boundary user password"
 default     = ""
}


