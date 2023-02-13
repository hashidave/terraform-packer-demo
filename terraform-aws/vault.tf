### Create a couple of policies that will be applied to the token we're 
### about to create. This token will be handed off to boundary for it's 
### credential stores
resource "vault_policy" "boundary_token_policy"{
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

resource "vault_policy" "boundary_credential_policy" {
  name = "boundary-credential-policy"
  policy= <<EOT
      path "kv/data/userdata" {
        capabilities = ["read"]
      }

      #path "kv/data/GoldenImage-UserPW-dev" {
      #  capabilities = ["read"]
      #}
  EOT 
}


# Create a vault token to hand off to boundary
resource "vault_token" "boundary_vault_token"{
  period            = "168h"
  no_default_policy = false
  no_parent         = true
  #give it all the policies that we created above plus the general one
  policies= ["boundary-token-policy","boundary-credential-policy"]
}

#### Provision some default secrets into vault

# first we need to mount kv
resource "vault_mount" "kv" {
  path      = "kv"
  type      = "kv-v2"
  #options   = { version = "2" }
}

# Generate a random password for our user
resource "random_password" "user-password" {
  length           = 16
  special          = true
  override_special = "+_-"
}

# have to introduce a delay between creating the kv2 mount & trying 
# to write a secret to it.
resource "time_sleep" "wait_30_seconds" {
  depends_on = [vault_mount.kv]
  create_duration = "30s"
}

resource "vault_kv_secret_v2" "userdata" {
  mount                      = vault_mount.kv.path
  name                       = "userdata"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    private_key = var.ssh_private_key,
    username    = var.default_username,
    password    = random_password.user-password.result
  }
  )
  custom_metadata {
    max_versions = 5
  }
  # gotta wait a bit..
  depends_on = [time_sleep.wait_30_seconds]
}
