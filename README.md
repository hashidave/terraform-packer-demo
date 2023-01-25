## Infrastructure Workflow Demo
This repo demonstrates golden image workflows with remote access and shows off
HCP Packer, HCP Vault, TFCB, and HCP Boundary 
Emphasis is on how the products work together

There is a lot of stuff in here, different environments, etc.  The only environment that fully works today is AWS

### Top-Level Folder Structure
packer-aws - Packer build in AWS for a base ubuntu image, a web-app image, and an HCP Boundary worker image.

packer-gcp - do not use at this time.  

packer-win-aws - builds a Windows image for AWS.  Slated to be moved out of this repo.  
terraform-aws-base-testing - test harness.  deploys just a base AWS ubuntu image for dev purposes

terraform-aws-webapp-testing - test harness.  deploys just the AWS webapp server image for dev purposes

terraform-aws - deploys the current 

### Branches
- Dev - Development work.  May not be stable at any given moment
- Prod - Stable codebase for running demos

### Pre-Requisites
- Create an HCP account
  - Create an HCP Vault cluster
  - Create an HCP Boundary cluster
  - Create an HCP packer registry
- Create or access an existing Terraform Cloud Organization with "Team & Governance Plan" features enabled.
- Create a Service Principal for the target Organization in portal.cloud.hashicorp.com, Access Control (IAM).
  - Capture the Client ID and Secret
- AWS
  - Create AWS IAM User/Access Keys used by Terraform for Deployment with the "AdministratorAccess" permission set in the target AWS account. 
    - Capture the Access Key ID and Secret.
  - Create AWS IAM User/Access Keys for Boundary host set populationwith the "ec2:DescribeInstances" permission set in the target AWS account. 
    - Capture the Access Key ID and Secret.
Set up HCP Boundary items
  - Create (or use) an avaialable project.
  - Create a user in HCP boundary called "tf-workspace"
  - Create a role scoped to the project.  Map to the tf-workspace user with a grant string of id=*;type=*;actions=create,read,update,delete
- GCP (DO NOT USE)
  - Create a Service Account user with the Editor role, generate key in JSON.
    - Capture the key
- Create a Variable Set in Terraform Cloud containing the following Environment variables.  These will be used to drive the overall HCP and TF environment 
  - HCP_CLIENT_ID
  - HCP_CLIENT_SECRET (sensitive)
  - AWS User for TF Deployment
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY (sensitive)
  - AWS User for Boundary host set population
    - TF_VAR_AWS_SECRET_KEY_BOUNDARY_USER
    - TF_VAR_TF_WORKSPACE_PWD  (set to the password of the "tf-workspace" user in HCP Boundary)
  - GCP (Not currently stable.  Do not use) 
    - GOOGLE_CREDENTIALAS (sensitive)
  - TF_VAR_TF_WORKSPACE_PWD
- Create an HCP-Packer Run Task in your Terraform Cloud Organization
  - Retrieve the "Endpoint URL" and "HMAC Key" from the HCP Packer / "Integrate with Terraform Cloud" page under portal.cloud.hashicorp.com

### Packer
Inside the packer-aws folder 

- packer init .
- packer fmt .
- Build the base AWS image
  - HCP_PACKER_BUILD_FINGERPRINT="$(date +%s)" packer build 1-acme-base.pkr.hcl
  - Assign image to "Dev" channel of the acme-base bucket
- Build the Web App image
  - HCP_PACKER_BUILD_FINGERPRINT="$(date +%s)" packer build 2-acme-webapp.pkr.hcl
  - Assign the image to the "Dev" channel of the acme-webapp bucket
- Build the HCP Boundary worker image
  - HCP_PACKER_BUILD_FINGERPRINT="$(date +%s)" packer build 5-boundary-worker.pkr.hcl 
  - Assign the image to the "Dev" channel of the acme-webapp bucket
- 
- Assign image to "production" Channel

### Terraform

- Edit terraform/terraform.tf and populate the Organization and Workspace names
- terraform init
- Assign the credentials Variable Set to the workspace, unless you created the Variable Set as organization-wide
- Assign HCP Packer Run Task to Workspace
- terraform plan
- terraform apply

### Revoke Image
- Revoke acme-webapp Iteration
- terraform plan
- terraform apply

### Update Image
- HCP_PACKER_BUILD_FINGERPRINT="$(date +%s)" packer build 3-acme-base.pkr.hcl
- Assign image to "development" channel
- HCP_PACKER_BUILD_FINGERPRINT="$(date +%s)" packer build 4-acme-webapp.pkr.hcl
- Assign image to "development" channel
- Modify terraform/web_app.tf, point to "development"
- terraform apply

### Various repositories were borrowed from to construct this demo.
- https://github.com/brokedba/terraform-examples
# packer-terraform-demo
# terraform-packer-demo
