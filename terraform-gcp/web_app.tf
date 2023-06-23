#---------------------------------------------------------------------------------------
# HCP Packer Configuration
#---------------------------------------------------------------------------------------
variable "hcp_bucket_name" {
  default = "acme-webapp"
}


data "hcp_packer_iteration" "ubuntu" {
  bucket_name = var.hcp_bucket_name
  channel     = var.environment
}

data "hcp_packer_image" "ubuntu_gcp" {
  bucket_name    = var.hcp_bucket_name
  cloud_provider = "gce"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = var.zone
}


#---------------------------------------------------------------------------------------
# Instances
#---------------------------------------------------------------------------------------
resource "google_compute_instance" "terraform_instance" {
  name         = var.instances_name
  hostname     = var.hostname
  project      = var.GCP_Project_ID
  zone         = var.zone
  machine_type = var.vm_type
  
  #NOTE:  Tags have to be lower case!!
  tags = ["web-server", "lunch", "butters", "foo", "grail", "neegan", "robotvacuum"]
  
  
  #metadata = {
  #  ssh-keys = "${var.admin}:${file("id_rsa.pub")}"
  #}

  network_interface {
    network            = "${module.terraform_vpc.network_self_link}"
    subnetwork         = google_compute_subnetwork.terraform_sub.self_link
    subnetwork_project = var.GCP_Project_ID
    network_ip         = var.private_ip

    access_config {
      // Include this section to give the VM an external ip address
    }
  }


  #---------------------------------------------------------------------------------------
  # Computer Image
  #---------------------------------------------------------------------------------------
  boot_disk {
    initialize_params {
      image = data.hcp_packer_image.ubuntu_gcp.cloud_image_id
    }
  }
  # scratch_disk {
  #  interface = "SCSI"
  #}

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }


  # service account
  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }
}


#---------------------------------------------------------------------------------------
# IP Address
#---------------------------------------------------------------------------------------
# Reserving a static internal IP address 
resource "google_compute_address" "internal_reserved_subnet_ip" {
  name         = "internal-address"
  subnetwork   = google_compute_subnetwork.terraform_sub.id
  address_type = "INTERNAL"
  address      = var.private_ip
  region       = var.region
}

#resource "google_compute_address" "static" {
#  name = "ipv4-address"
#}
