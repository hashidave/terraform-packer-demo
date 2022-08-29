#---------------------------------------------------------------------------------------
# VPC
#---------------------------------------------------------------------------------------
#resource "google_compute_network" "terraform_vpc" {
#  project                 = var.gcp_project
#  name                    = "terraform-vpc"
#  auto_create_subnetworks = false
#}

module "terraform_vpc" {
      source  = "terraform-google-modules/network/google//modules/vpc"
      version = "5.2.0"
      network_name="dave-test-net"
      project_id=var.gcp_project
}


#---------------------------------------------------------------------------------------
# Subnet
#---------------------------------------------------------------------------------------
resource "google_compute_subnetwork" "terraform_sub" {
  name                     = var.subnet_name
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = module.terraform_vpc.google_compute_network.network.name
  description              = "Terraform Demo Subnet"
  private_ip_google_access = "true"
}


#---------------------------------------------------------------------------------------
# Firewall
#---------------------------------------------------------------------------------------
resource "google_compute_firewall" "web-server" {
  project     = var.gcp_project
  name        = "allow-http-rule"
  network     = module.terraform_vpc.newtork_name
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "443", "3389"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  timeouts {}
}
