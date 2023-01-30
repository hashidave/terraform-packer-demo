## Vault configuration

# Create a DB Connection
resource "vault_database_secret_backend_connection" "postgres" {
 count = var.db-count
  #backend       = "database/postgres-${var.prefix}-${var.environment}"
  backend       = "database"
  name          = "postgres-${var.prefix}-${var.environment}-${count.index}"
  allowed_roles = ["rw-${count.index}", "ro-${count.index}"]

  postgresql {
    connection_url = "postgres://dmradmin:${random_password.pg-password.result}@${aws_db_instance.db-instance.address}:${aws_db_instance.db-instance.port}/postgres"
  }
}

# Create a read-write role
resource "vault_database_secret_backend_role" "rw-role" {
  count               = var.db-count
# backend             = "database/postgres-${var.prefix}-${var.environment}"
  backend             = "database"
  name                = "rw-${count.index}"
  db_name             = vault_database_secret_backend_connection.postgres[count.index].name
  creation_statements = ["CREATE ROLE '{{name}}' WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT pg_write_all_data TO '{{name}}';"
                        ]
  default_ttl         = 3600
}


# Create a read-only role
resource "vault_database_secret_backend_role" "role" {
  count= var.db-count
#  backend             = "database/postgres-${var.prefix}-${var.environment}" 
  backend             = "database"
  name                = "ro-${count.index}"
  db_name             = vault_database_secret_backend_connection.postgres[count.index].name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT pg_read_all_data to '{{name}}';"
                        ]
  default_ttl         = 3600
}

# set up roles so that boundary can generate secrets
resource "vault_policy" "read-write" {
  count = var.db-count
  name = "read-postgres-${var.prefix}-${var.environment}-${count.index}"

  policy = <<EOT
path "database/postgres/postgres-{$var.prefix}-${var.environment}-${count.index}/ro" {
  capabilities = ["read"]
}
path "database/postgres/postgres-{$var.prefix}-${var.environment}-${count.index}/rw" {
  capabilities = ["read"]
}

EOT
}

