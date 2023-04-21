output "login-command-template"{
  value="boundary authenticate password -auth-method-id ${boundary_auth_method_password.auth-method-pw.id} -login-name mr-readonly-<env>"

}

output "boundary_ro_brokered_connection_commands"{
  value=formatlist ("boundary connect postgres -target-id=%s -dbname=postgres", boundary_target.rds-readonly[*].id )
}

#output "boundary_rw-injected_connection_commands"{
#  value=formatlist ("boundary connect postgres -target-id=%s -dbname=postgres", boundary_target.rds-readwrite-injected[*].id)
#}

output "boundary_rw-brokered_connection_commands"{
  value=formatlist ("boundary connect postgres -target-id=%s -dbname=postgres", boundary_target.rds-readwrite-brokered[*].id)
}


output "hcp_boundary_worker_ip_from_boundary" {
  value = boundary_worker.private-worker.address
}

output "hcp_boundary_worker_ip_from_ec2" {
  value = aws_eip.boundary-worker.public_ip
}

##########################################
# for debugging only. turn this off...
output "random-password"{
 value=random_password.pg-password[*].result
 sensitive=true
}

#output "boundary-vault-token"{
# value= vault_token.boundary_vault_token.client_token
# sensitive=true
#}

#output "boundary_worker_ec2_ip" {
#  value = aws_eip.boundary-worker.public_ip
#}

########################################

#output "connection-urls" {
#  value = local.connection-urls
#  sensitive = true
#}


#output "rds-connection-string"{
#  value=local.connection_string[*]
#  sensitive=true
#}
#

#output "policy-set"{
#  value = concat (["general-token-policy"], vault_policy.read-write[*].name)
#}


#output "credential-library-paths"{
#  value= boundary_credential_library_vault.vault-library-readwrite[*].path
#}

#output "test"{
#  value=formatlist("cidr:%s/32", aws_eip.hashicat.*.public_ip)
#}

output "readonly-user-name"{
  value=boundary_account_password.mr-readonly.login_name
}

output "readwrite-user-name"{
  value=boundary_account_password.mr-readwrite.login_name
}
