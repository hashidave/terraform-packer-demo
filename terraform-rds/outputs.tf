
#output "controller_token" { 
#  value =boundary_worker.private-worker.controller_generated_activation_token
#}

#output "boundary_worker_ec2_ip" {
#  value = aws_eip.boundary-worker.public_ip
#}

#output "hcp_boundary_worker_ip" {
#  value = boundary_worker.private-worker.address
#}


# for debugging only. turn this off...
output "random-password"{
 value=random_password.pg-password.result
 sensitive=true
}


output "rds-url"{
  value ="postgres://dmradmin:${random_password.pg-password.result}@${aws_db_instance.db-instance.address    }:${aws_db_instance.db-instance.port}/postgres"
}

#output "test"{
#  value=formatlist("cidr:%s/32", aws_eip.hashicat.*.public_ip)
#}

