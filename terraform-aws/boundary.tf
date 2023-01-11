# Get the project ID from the main boundary project
data "tfe_outputs" "Boundary" {
  organization = "hashi-DaveR"
  workspace = "Boundary-Environment"
}


#resource "boundary_host_catalog_plugin" "host_catalogd" {
#  name            = "GoldenImage AWS Dev Catalog"
#  description     = ""
#  scope_id        = tfe_outputs.Boundary.host_catalog
#  plugin_name     = "aws"
#  attributes_json = jsonencode({ 
#	"region" = "us-east-2"
#	"disable_credential_rotation"=true
# 
#  })
 
#  # recommended to pass in aws secrets using a file() or using environment variables
  # the secrets below must be generated in aws by creating a aws iam user with programmatic access
#  secrets_json = jsonencode({
#    "access_key_id"     = var.AWS_ACCESS_KEY_BOUNDARY_USER
#    "secret_access_key" = var.AWS_SECRET_KEY_BOUNDARY_USER
#  })
#}

resource "boundary_host_set_plugin" "host_set" {
  name            = "GoldenImage AWS Dev Host Set"
  host_catalog_id = data.tfe_outputs.Boundary.nonsensitive_values.host_catalog
  attributes_json = jsonencode({ "filters" = "tag:host-set=DMR_GOLDEN_IMAGE_AWS_DEV" })

  # Have to set the endpoints to whatever IP Addresses that AWS asssigns
  preferred_endpoints=formatlist("cidr:%s/32", aws_eip.hashicat.*.public_ip)

}






