## Vault configuration
resource "vault_mount" "database" {
  path      = "${var.prefix}-${var.environment}"
  type      = "database"
}

locals{ 
  connection-urls = "${formatlist("postgres://dmradmin:%s@%s:%s/postgres", random_password.pg-password.result, aws_db_instance.db-instance[*].address, aws_db_instance.db-instance[*].port)}"
}  

# Create a DB Connection
resource "vault_database_secret_backend_connection" "postgres" {
  count         = var.db-count
  backend       = vault_mount.database.path
  name          = "postgres-${var.prefix}-${var.environment}-${count.index}"
  allowed_roles = [
        "postgres-${var.prefix}-${var.environment}-${count.index}-ro",
        "postgres-${var.prefix}-${var.environment}-${count.index}-rw"
  ]              
  
 postgresql {
    connection_url = local.connection-urls[count.index]
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
  default_ttl         = 360

}


# Create a read-only role
resource "vault_database_secret_backend_role" "ro-role" {
  count= var.db-count
  backend             = vault_database_secret_backend_connection.postgres[count.index].backend
  name                = "${vault_database_secret_backend_connection.postgres[count.index].name}-ro"
  db_name             = vault_database_secret_backend_connection.postgres[count.index].name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
                         "GRANT pg_read_all_data to \"{{name}}\";"
                          ]
  default_ttl         = 360
}



# set up roles so that boundary can generate secrets
resource "vault_policy" "read-write-postgres" {
  count = var.db-count
  name = "boundary-readwrite-postgres-${var.prefix}-${var.environment}-${count.index}"

  policy = <<EOT
path "${vault_mount.database.path}/creds/${vault_database_secret_backend_role.ro-role[count.index].name}" {
  capabilities = ["read", "list"]
}
path "${vault_mount.database.path}/creds/${vault_database_secret_backend_role.rw-role[count.index].name}" {
  capabilities = ["read", "list"]
}

EOT
}

resource "vault_policy" "boundary_token_policy"{
  count = var.db-count
  name = "boundary-token-policy"
  
  policy= <<EOT
      path "auth/token/lookup-self" {
        capabilities = ["read"]
      }
      path "auth/token/renew-self" {
        capabilities = ["update"]
      }
      path "auth/token/revoke-self" {
        capabilities = ["update"]
      }
      path "auth/token/create" {
        capabilities = ["create", "read", "update", "list"]
      }
      path "sys/leases/renew" {
        capabilities = ["update"]
      }
      path "sys/leases/revoke" {
        capabilities = ["update"]
      }
      path "sys/capabilities-self" {
        capabilities = ["update"]
      }
    EOT  
}



# Create a vault token to hand off to boundary
resource "vault_token" "boundary_vault_token"{
  period            = "168h"
  no_default_policy = false
  no_parent         = true
  #give it all the policies that we created above plus the general one
  policies= concat (["boundary-token-policy"], vault_policy.read-write-postgres[*].name)
  #policies = vault_policy.read-write[*].name
}

