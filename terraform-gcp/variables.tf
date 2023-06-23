#--------------------------------------------------------------------------------------
# GCP Project and Region
#--------------------------------------------------------------------------------------
variable "prefix"{
  default="terraform-dev"
}

variable "environment"{
  default="dev"  
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}


#--------------------------------------------------------------------------------------
# VPC
#--------------------------------------------------------------------------------------
variable "vnet_name" {
  default = "terraform-network"
}


#--------------------------------------------------------------------------------------
# Subnets
#--------------------------------------------------------------------------------------
variable "subnet_name" {
  default = "terraform-subnet"
}

variable "subnet_cidr" {
  default = "192.168.10.0/24"
}

variable "firewall_name" {
  default = "terraform-firewall"
}

variable "GCP_Project_ID" {  
}

variable "instances_name" {
  default     = "terraformvm"
}

variable "admin" {
  description = "OS user"
  default     = "ubuntu"
}


#--------------------------------------------------------------------------------------
# VNic Configuration
#--------------------------------------------------------------------------------------
variable "private_ip" {
  default = "192.168.10.51"
}

variable "boundary_worker_ip" {
  default = "192.168.10.52"
}


variable "hostname" {
  description = "Hostname of instances"
  default     = "web-app-1.alluvium.com"
}


#--------------------------------------------------------------------------------------
# Compute Instance
#--------------------------------------------------------------------------------------
variable "instance_name" {
  default = "terraform-webapp"
}

variable "osdisk_size" {
  default = "30"
}

variable "vm_type" {   # gcloud compute machine-types list --filter="zone:us-east1-b and name:e2-micro"
  default = "e2-micro"
}

variable "ssh_private_key"{
}

#----------------------------------------------
#     HCP Boundary Config
#----------------------------------------------
variable "boundary-cluster-id"{
}

variable "boundary-address"{
}
variable "VAULT_ADDR" {
  description = "this gets populated from a workspace variable if you used the tfc workspace factory"
 
}
variable "TFC_VAULT_NAMESPACE" {
  description = "this gets populated from a workspace variable"
}

