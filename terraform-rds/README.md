## Terraform RDS
This repo spins up an example of how boundary might be leveraged in the real world to access an environment of ephemeral databases.  
Since the beauty of terraform is that I can spin up multiple copies of an environment with just a few variable changes, one of the challenges becomes greenfield deployment of a boundary worker.  There is some amount of toil involved in this so one design goal was to entirely automate this proces.  Here's how it go:

We use an HCP Packer image for the worker deployment that is created from /packer-aws/5-boundary-worker.pkr.hcl (which relies on the base template of 1-acme-base.pkr.hcl.  Another design goal was to show examples of best practice when possible)
This image contains a templatized boundary.hcl file which is completed by terraform, using a null_resource remote-exec provisioner, at deployment time.  

At this point it's the responsible thing to point out a current gotcha:  The boundry_worker provider in TF has a little bug that causes it to be destroyed and re-created on every apply.  When this happens the worker token changes and if there is an existing worker, it breaks.  I've got the logic in place to re-run the provisioner when this happens but it doesn't fix the worker.  I plan to debug this at some point, or you can, but the interim solution is to taint the aws_instance.boundary-worker resource before any applies.  To make this easy there is an ./apply.sh script that does this for you


Anyway, based on the db-count variable, Terraform will deploy some number of RDS instances.  They all have a default database name of postgres.  Keep that in mind for later.  It then craetes a Boundary host set and static hosts for each rds instance.  Two targets are then created for the host set.  Both targets use dynamic db credentials (fetched from appropriately named Boundary credential libraries) from vault (all provisioned from vault.tf) with one set being read-only and one being read-write.  Roles for each thing are also set up such that access to targets is limited to one of the users (also dynamically created) called "mr-readonly" and "mr-readwrite"  according to their respective abilties.  

Both mr-readonly and mr-readwrite have a Boundary password of $uper$ecure



There is a consistent naming convention enforced for objects in the form of prefix-environment-index-access.   
The components of that are populated with TF variables and count indices.  Not all objects need all those attributes to be identified but you should be able to identify what any vault or boundary object does.

### What should I do once it applies?
First of all, you can study the objects in Vault and Boundary.  Since they have such nice names it's pretty easy to follow the logic.  

Second, you can connect to the instances.  You'll need to get the password auth method id for the ORG as well as the target ids for your various targets.  The command to connect is 
boundary connect postgres -target-id=<target> -dbname=postgres

Third, you can find ways to improve it.  Pull requests are welcome.  There is still a lot of room for improvement here.  

## Deployment
### pre-requisites
First of all:  Do ALL the things in the master repo instructions.  (navigate to ../README.md to find them)

All commands should run out of the terraform-rds folder.

Make sure your terraform workspace for the https://github.com/hashidave/boundary-dmr repo has the state shared with the project for this repo.

### Vault
Create a namespace to use.  This demo runs in HCP vault & assumes a parent namespace of admin/terraform_workloads but you can make whatever you want as long as you set the terraform variable described below.  


- This policy called **terraform-demos** created in your **root** or **admin** namespace
```
path "terraform-demos" {
	capabilities = ["sudo","read","create","update","delete","list","patch"]
}

path "terraform-demos/*" {
	capabilities = ["sudo","read","create","update","delete","list","patch"]
}

#path "sys/mounts/terraform-demos/*" {
##  capabilities = ["create", "update"]
#}

path "sys/mounts/*" {
  capabilities = ["create", "update"]
}

#path "database/*" {
	#capabilities = ["sudo","read","create","update","delete","list","patch"]
#}

# Write ACL policies
#path "sys/policies/acl/*" {
#  capabilities = [ "create", "read", "update", "delete", "list" ]
#}
```

- and this policy called **tf-create-token** in your **root** or **admin** namespace
```
path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}
```


### Terraform
For maxiumum ease of use, use this repo to create a new workspace:  https://github.com/hashidave/tfc-workspace-factory
By default, one will be created called "workspace1". Use that one.

tag that workspace with **boundary-rds**


-ssh_private_key - another environment var.  Should be the ssh key from the keypair you generated in the master repo instructions.  Pro-tip:  Take out the newlines before you try to paste it into an environment var. 

-boundary-address - the address of your boundary cluster

-boundry-cluster-id - your boundary cluster id.  
 
- boundary_auth_method_id - the id of the auth method containing your tf-workspace user
 
- db-count - the number of rds instances you want to spin up.  

At this point, you should be feature-complete & ready to roll.  

Run terraform init/plan/apply