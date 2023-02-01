##############################################################
####   Get the project ID from the main boundary project  ####
##############################################################
data "tfe_outputs" "Boundary" {
  organization = "hashi-DaveR"
  workspace = "Boundary-Environment-dev"
}

##########################################################################
####  Provision a static host catalog into the project               ##### 
##########################################################################
resource boundary_host_catalog_static "rds_host_catalog"{
  name            = "Static Host Catalog ${var.prefix} ${var.environment}"
  description     = "${var.prefix} ${var.environment} static host catalog"
  #type            = "static"
  scope_id        = data.tfe_outputs.Boundary.nonsensitive_values.demo-project-id 
}



##########################################################################
####  Provision a static host set into the catalog                   ##### 
##########################################################################
resource "boundary_host_set_static" "rds_host_set" {
  name            = "${var.prefix} ${var.environment} RDS Host Set"
  type            = "static"
  # The host catalog comes from an external state for our general boundary environment
  host_catalog_id = boundary_host_catalog_static.rds_host_catalog.id
}

##########################################################################
#### Create host object & load the RDS instances into the host set   ##### 
##########################################################################
resource boundary_host_static rds_host{
  type            = "static"
  #name            = aws_db_instance.db-instance.name
  name = "db1"
  #description     = "rds database ${aws_db_instance.db-instance.name}"
  address         = aws_db_instance.db-instance.address
  host_catalog_id = boundary_host_catalog_static.rds_host_catalog.id
  #host_catalog_id = boundary_host_set_static.rds_host_set.id
}


#######################################
############ Credential Info ##########
#######################################
resource "boundary_credential_store_vault" "vault-store-rds" {
  name        = "vault-store-rds-${var.environment}"
  description = "Demo connection to my HCP Vault for ${var.environment}"
  address     = var.vault-cluster
  token       = vault_token.boundary_vault_token.client_token
  scope_id    = data.tfe_outputs.Boundary.nonsensitive_values.demo-project-id 
  namespace   = "admin/terraform-demos"
}

### Cred library for a dynamic secret from a read-write role
resource "boundary_credential_library_vault" "vault-library-readwrite" {
  count               = var.db-count
  name                = "hcp-vault-library-readwrite-${var.environment}-${count.index}"
  description         = "HCP Vault credential library for read-write creds in ${var.environment} - ${count.index}"
  credential_store_id = boundary_credential_store_vault.vault-store-rds.id
  credential_type     = "username_password"
  path                = "database/${vault_database_secret_backend_role.rw-role[count.index].name}"
  http_method         = "GET"
}

### Cred library for a dynamic secret from a read-only role
resource "boundary_credential_library_vault" "vault-library-readonly" {
  name                = "hcp-vault-library-readonly-${var.environment}"
  description         = "HCP Vault credential library for read-only creds in ${var.environment}"
  credential_store_id = boundary_credential_store_vault.vault-store-rds.id
  credential_type     = "username_password"
  path                = "kv/data/GoldenImage${var.environment}" # change to Vault backend path
  http_method         = "GET"
}


####################################
######  The targets   ##############
####################################
resource "boundary_target" "rds-readwrite" {
  name         = "rds-readwrite-${var.environment}"
  count        = var.db-count
  description  = "rds target with read-write creds injected"
  type         = "tcp"
  default_port = "22"
  scope_id     = data.tfe_outputs.Boundary.nonsensitive_values.demo-project-id 
  host_source_ids = [
    boundary_host_set_static.rds_host_set.id
  ]
  
  brokered_credential_source_ids = [
    boundary_credential_library_vault.vault-library-readwrite[count.index].id
  
  ]
  
  worker_filter="\"${var.prefix}\" in \"/tags/project\" and \"dev\" in \"/tags/env\""
}

resource "boundary_target" "rds-readonly" {
  name         = "rds-readonly-${var.environment}"
  description  = "rds target with read-only creds injected"
  count        = var.db-count
  type         = "tcp"
  default_port = "5432"
  scope_id     = data.tfe_outputs.Boundary.nonsensitive_values.demo-project-id 
  host_source_ids = [
    boundary_host_set_static.rds_host_set.id
  ]
  
  brokered_credential_source_ids = [
    boundary_credential_library_vault.vault-library-readonly[count.index].id
  ]
  
  worker_filter="\"${var.prefix}\" in \"/tags/project\" and \"dev\" in \"/tags/env\""
}

####################################
######  Test Users    ##############
####################################
resource "boundary_auth_method_password" "auth-method-pw"{
  scope_id      = data.tfe_outputs.Boundary.nonsensitive_values.org_scope
  name          = "${var.prefix}-${var.environment}-password"
  description   = "Password auth for ${var.prefix}-${var.environment}"
}

resource "boundary_account_password" "mr-readonly" {
  auth_method_id = boundary_auth_method_password.auth-method-pw.id
  type           = "password"
  login_name     = "mr-readonly-${var.environment}"
  password       = "$uper$ecure"
}

resource "boundary_user" "mr-readonly" {
  name        = "mr-readonly-${var.environment}"
  description = "Mr Readonly's user resource"
  account_ids = [boundary_account_password.mr-readonly.id]
  scope_id    = data.tfe_outputs.Boundary.nonsensitive_values.org_scope
}

resource "boundary_account_password" "mr-readwrite"{
  auth_method_id = boundary_auth_method_password.auth-method-pw.id
  type           = "password"
  login_name     = "mr-readwrite-${var.environment}"
  password       = "$uper$ecure"
}

resource "boundary_user" "mr-readwrite" {
  name        = "mr-readwrite-${var.environment}"
  description = "Mr Readwrite's user resource"
  account_ids = [boundary_account_password.mr-readwrite.id]
  scope_id    = data.tfe_outputs.Boundary.nonsensitive_values.org_scope

}



####################################
######  Test Roles    ##############
####################################
resource "boundary_role" "readonly" {
  name          = "${var.prefix}-${var.environment}-readonly"
  count         = var.db-count
  description   = "A readonly role"
  principal_ids = [boundary_user.mr-readonly.id]
  grant_strings = ["id={boundar_target.rds_readonly[count.index].id};type=*;actions=read"]
  scope_id      = data.tfe_outputs.Boundary.nonsensitive_values.demo-project-id
}

resource "boundary_role" "readwrite" {
  name          = "${var.prefix}-${var.environment}-readwrite"
  count         = var.db-count
  description   = "A readwrite role"
  principal_ids = [boundary_user.mr-readwrite.id]
  grant_strings = ["id={boundar_target.rds_readwrite.id};type=*;actions=read"]
  scope_id      = data.tfe_outputs.Boundary.nonsensitive_values.demo-project-id
}


#################################################################################################################
####  The self-managed worker                                                                               #####
# This is non-trivial to deploy.  First you need an HCP boundary_worker object                              ##### 
# which will generate a token that has to be passed into the ec2 instance and injected into a config file   #####
# Currently this is being done with a remote-exec provisioner but plan is to                                #####  
# use AWS user-data when the ec2 is provisioned to pass that along.                                         ##### 
# ###############################################################################################################

# Create a controller-lead HCP Boundary Worker Object
resource "boundary_worker" "private-worker"{
  scope_id    = "global" 
  description = "${var.prefix} Workflow Worker"
  name        = "${var.prefix}-worker"

  # The activation token on the HCP side is only available on the apply that creates the boundary_worker objevct
  # so if we later change the worker ec2 instance for any reason we have to re-create the HCP boundary_worker
  # so that we can get the token back.  I supppose we could store it in Vault but that's a task for future Dave.
  lifecycle{
     replace_triggered_by=[aws_instance.boundary-worker]
  }
}



# Deploy a boundary worker EC2 into our environment
  data "hcp_packer_iteration" "boundary-worker" {
    bucket_name = "boundary-workers"
    channel     = var.environment 
  } 
 
  data "hcp_packer_image" "boundary-worker" {
    bucket_name    = "boundary-workers"
    cloud_provider = "aws"
    iteration_id   = data.hcp_packer_iteration.boundary-worker.ulid
    region         = var.region
  }
 
  resource "aws_instance" "boundary-worker" {
    ami                         = data.hcp_packer_image.boundary-worker.cloud_image_id
 
   instance_type               = var.instance_type
    key_name                    = "DaveTestKey-Ohio"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.BoundaryRDS1.id
    vpc_security_group_ids      = [aws_security_group.boundary-worker.id]
   
    tags = {
      Type="Boundary_Worker",
      Name = "${var.prefix}-BoundaryWorker",
      Environment = var.environment
    }

  }



  # This exist only to get around the circular dependency between the worker & the aws_eip
  # that we have to put into the config file.
  # should update in the future to use some kind of user-data structure that gets passed in
  # when the cloud provisions the instance
  resource "null_resource" "worker-provisioner" {
    triggers={
      worker-id=aws_instance.boundary-worker.id,
      worker-ip=aws_eip.boundary-worker.public_ip
    }
       

    connection {
       type     = "ssh"
       user     = "ubuntu"
       host     = aws_eip.boundary-worker.public_ip
       port     = 22
       private_key = var.ssh_private_key
     }


     #Provisioner will fill out the stub config file with some important 
     #Boundary info & restart the boundary-worker service
     provisioner "remote-exec" {
       inline=[
         "sudo sed -i ''s/CLUSTER_ID_HERE/${var.boundary-cluster-id}/g'' /etc/boundary.d/boundary.hcl",
	
         "sudo sed -i ''s/CONTROLLER_GENERATED_TOKEN_HERE/${boundary_worker.private-worker.controller_generated_activation_token}/g'' /etc/boundary.d/boundary.hcl",
         "sudo sed -i ''s/WORKER_PUBLIC_IP_HERE/${aws_eip.boundary-worker.public_ip}/g'' /etc/boundary.d/boundary.hcl",
	 "sudo sed -i ''s/ENVIRONMENT_TAG_HERE/${var.environment}/g'' /etc/boundary.d/boundary.hcl",
         "sudo sed -i ''s/PROJECT_TAG_HERE/${var.prefix}/g'' /etc/boundary.d/boundary.hcl",
	 "sudo service boundary --full-restart"
       ]
     }
 }


resource "aws_eip" "boundary-worker" {
  instance = aws_instance.boundary-worker.id
  vpc      = true
}

resource "aws_eip_association" "boundary-worker" {
  instance_id   = aws_instance.boundary-worker.id
  allocation_id = aws_eip.boundary-worker.id
}



resource "aws_security_group" "boundary-worker" {
  name = "boundary-worker-security-group"

  vpc_id = aws_vpc.BoundaryRDS.id
ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9202
    to_port     = 9202
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
}



