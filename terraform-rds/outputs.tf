output "hcp_boundary_worker_ip_from_boundary" {
  value = boundary_worker.private-worker.address
}

output "hcp_boundary_worker_ip_from_ec2" {
  value = aws_eip.boundary-worker.public_ip
}

##########################################
# for debugging only. turn this off...
#output "random-password"{
# value=random_password.pg-password.result
# sensitive=true
#}

#output "boundary-vault-token"{
# value= vault_token.boundary_vault_token.client_token
# sensitive=true
#}

#output "boundary_worker_ec2_ip" {
#  value = aws_eip.boundary-worker.public_ip
#}

########################################


output "rds-url"{
  value ="postgres://dmradmin:${random_password.pg-password.result}@${aws_db_instance.db-instance.address    }:${aws_db_instance.db-instance.port}/postgres"
  sensitive=true
}


output "policy-set"{
  value = concat (["general-token-policy"], vault_policy.read-write[*].name)
}


#output "test"{
#  value=formatlist("cidr:%s/32", aws_eip.hashicat.*.public_ip)
#}

