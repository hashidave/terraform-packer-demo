## Vault configuration
resource "vault_mount" "database" {
  path      = "database"
  type      = "database"
}

# Create a DB Connection
resource "vault_database_secret_backend_connection" "postgres" {
  count = var.db-count
  backend       = vault_mount.database.path
  name          = "postgres-${var.prefix}-${var.environment}-${count.index}"
  allowed_roles = ["rw-${count.index}", "ro-${count.index}"]

  postgresql {
    connection_url = "postgres://dmradmin:${random_password.pg-password.result}@${aws_db_instance.db-instance.address}:${aws_db_instance.db-instance.port}/postgres"
  }

  depends_on=[
    aws_db_instance.db-instance
  ]
}

# Create a read-write role
resource "vault_database_secret_backend_role" "rw-role" {
  count               = var.db-count
  backend             = vault_database_secret_backend_connection.postgres[count.index].backend
  name                = "${vault_database_secret_backend_connection.postgres[count.index].name}-rw"
  db_name             = vault_database_secret_backend_connection.postgres[count.index].name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
                         "GRANT pg_write_all_data TO \"{{name}}\";"
                        ]
  default_ttl         = 3600
}


# Create a read-only role
resource "vault_database_secret_backend_role" "role" {
  count= var.db-count
  backend             = vault_database_secret_backend_connection.postgres[count.index].backend
  name                = "${vault_database_secret_backend_connection.postgres[count.index].name}-ro"
  db_name             = vault_database_secret_backend_connection.postgres[count.index].name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
                         "GRANT pg_read_all_data to \"{{name}}\";"
                          ]
  default_ttl         = 3600
}


# set up roles so that boundary can generate secrets
resource "vault_policy" "read-write" {
  count = var.db-count
  name = "read-postgres-${var.prefix}-${var.environment}-${count.index}"

  policy = <<EOT
path "${vault_mount.database.path}/postgres/postgres-${var.prefix}-${var.environment}-${count.index}/ro" {
  capabilities = ["read"]
}
path "/${vault_mount.database.path}/postgres/postgres-${var.prefix}-${var.environment}-${count.index}/rw" {
  capabilities = ["read"]
}

EOT
}

# Create a vault token to hand off to boundary
resource "vault_token" "boundary_vault_token"{
  period            = "168h"
  no_default_policy = true
  no_parent         = true
    #give it all the policies that we created above plus the general one
  policies= concat (["general-token-policy"], vault_policy.read-write[*].name)

}

