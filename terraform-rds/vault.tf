## Vault configuration
#resource "vault_mount" "db" {
#  path = "database/postgres-{$var.prefix}-${var.environment}"
#  type = "database"
#}

# Create a DB Connection
resource "vault_database_secret_backend_connection" "postgres" {
#  backend       = "database/postgres-{$var.prefix}-${var.environment}"
  backend       = "database"
  name          = "postgres"
  allowed_roles = ["rw", "ro"]

  postgresql {
    connection_url = "postgres://dmradmin:${random_password.pg-password.result}@${aws_db_instance.db-instance.address}:${aws_db_instance.db-instance.port}/test}"
  }
}

# Create a read-write role
resource "vault_database_secret_backend_role" "rw-role" {
  backend             = "database/postgres-{$var.prefix}-${var.environment}"
  name                = "rw"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = ["CREATE ROLE '{{name}}' WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
                         "GRANT pg_write_all_data TO '{{name}}';"
                        ]
  default_ttl         = 3600
}


# Create a read-only role
resource "vault_database_secret_backend_role" "role" {
  backend             = "database/postgres-{$var.prefix}-${var.environment}" 
  name                = "ro"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
                         "GRANT pg_read_all_data to '{{name}}';"
                        ]
  default_ttl         = 3600
}

# set up roles so that boundary can generate secrets
resource "vault_policy" "read-write" {
  name = "read-postgres-${var.prefix}-${var.environment}"

  policy = <<EOT
path "database/postgres/postgres-{$var.prefix}-${var.environment}/ro" {
  capabilities = ["read"]
}
path "database/postgres/postgres-{$var.prefix}-${var.environment}/rw" {
  capabilities = ["read"]
}

EOT
}

