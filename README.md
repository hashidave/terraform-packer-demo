## Infrastructure Workflow Demo
This repo demonstrates golden image workflows with remote access and shows off
HCP Packer, HCP Vault, TFCB, and HCP Boundary
HCP Boundary has a couple of environments: ssh and rds connections 
Emphasis is on how the products work together. 
As of 2/9/23 the repo now relies on Terraform Dynamic Workspace Credentials so that's a cool feature, too

There is a lot of stuff in here, different environments, etc.  The only environment that fully works today is AWS

### Top-Level Folder Structure
packer-aws - Packer build in AWS for a base ubuntu image, a web-app image, and an HCP Boundary worker image.

packer-gcp - DO NOT USE.  NOT STABLE.

packer-win-aws - builds a Windows image for AWS.  Slated to be moved out of this repo.  
terraform-aws-base-testing - test harness.  deploys just a base AWS ubuntu image for dev purposes

terraform-aws-webapp-testing - test harness.  deploys just the AWS webapp server image for dev purposes

terraform-aws - deploys some webservers along with a boundary worker
terraform-rds - Deploys an rds environment instead of ec2 instances

### Branches
- Dev - Development work.  May not be stable at any given moment
- Prod - Stable codebase for running demos

### Generic Pre-Requisites
Generally speaking, these items need to be configured for all of the demo projects.
The terraform-xxx projects will have specific requirements listed in their README.md files

- Create an HCP account
  - Set your HCP_ORGANIZATION, HCP_CLIENT_ID, HCP_CLIENT_SECRET, and HCP_PROJECT_ID local environment vars.
  - Create an HCP Vault cluster
  - Create an HCP Boundary cluster
  - Create an HCP packer registry
- Create or access an existing TFCB Organization with 
- Create a Service Principal for the target Organization in portal.cloud.hashicorp.com, Access Control (IAM).
  - Capture the Client ID and Secret
- AWS
  - Create AWS IAM User/Access Keys used by Terraform for Deployment with the "AdministratorAccess" permission set in the target AWS account. 
    - Capture the Access Key ID and Secret.
  - Create AWS IAM User/Access Keys for Boundary host set populationwith the "ec2:DescribeInstances" permission set in the target AWS account. 
    - Capture the Access Key ID and Secret.
Set up HCP Boundary items
  - Create (or use) an avaialable project.
  - Create a user in HCP boundary called "tf-workspace"  **save the password**
  - Create a role scoped to the project.  Map to the tf-workspace user with a grant string of id=*;type=*;actions=create,read,update,delete
- GCP (DO NOT USE)
  - Create a Service Account user with the Editor role, generate key in JSON.
    - Capture the key
- Create a Variable Set in Terraform Cloud containing the following Environment variables.  These will be used to drive the overall HCP and TF environment.  **Don't forget to apply this to any workspaces you create for this project.**
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
- Create an HCP-Packer Run Task in your Terraform Cloud Organization
  - Retrieve the "Endpoint URL" and "HMAC Key" from the HCP Packer / "Integrate with Terraform Cloud" page under portal.cloud.hashicorp.com
  - An AWS KeyPair.  save the private key
### Configure Vault
Create these paths:
   kv/GoldenImage-dev (or -prod or whatever your environment is called)
     - private_key - the private key from the ssh keypair created above
   kv/GoldenImage-UserPW-dev (same note applies)
     - username - name of your choice
     - password - password of your choice
    kv/ubuntu-user
      - password - put a reasonably unpleasant password in here.  This will be used by Packer to do some 
                   image creation things.  


### Packer
Inside the packer-aws folder are templates to build the images you'll need in these environments
Go ahead & build them all now.  :)

- replace the files/authorized_keys with the public key that goes with the keypair you created above
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

### Configure Boundary
Although the projects stand up most of their own boundary stuff, you'll need to get some basic 
infrastructure created.  This repo will do that for you:  https://github.com/hashidave/boundary-dmr
Someday I'll love you enough to make a repo that does all the other stuff too. 
After you deploy it, don't forget that the other repos use the remote state of this one to figure out the Boundary project that they're supposed to deploy into so you'll need to enable state sharing with the other repos.

### Terraform
These apply to all the projects.  Again... see the project-specific readme for 
additional requirements.
- Tags are used to determine the terraform repo to use.  Specific tag info is documented in each project
- Ensure that the credentials Variable Set, created above, is assigned to the workspace
- Assign an HCP Packer Run Task to Workspace
- terraform init
- terraform plan
- terraform apply







### Various repositories were borrowed from to construct this demo.
- https://github.com/brokedba/terraform-examples
# packer-terraform-demo
# terraform-packer-demo

# Special Thanks
Eric Reeves who pioneered Packer templates for TOLA and gave me a repo with the underpinnings of the packer/tf integration
Nico Kabar who lent his insight and experience to this projet & who got me off high-center a few times.  
