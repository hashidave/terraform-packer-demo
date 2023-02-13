
output "boundary_controller_token" { 
  value =boundary_worker.private-worker.controller_generated_activation_token
}


output "boundary_injected_connection_commands"{
  value=formatlist ("boundary connect ssh -target-id=%s", boundary_target.server-ssh.id )
}

output "boundary_brokered_connection_commands"{
  value=formatlist ("boundary connect ssh -target-id=%s", boundary_target.server-ssh-brokered.id)
}

output "boundary_worker_ec2_ip" {
  value = aws_eip.boundary-worker.public_ip
}

output "boundary_worker_ip" {
  value = boundary_worker.private-worker.address
}

output "catapp_ip" {
  value = aws_eip.hashicat.*.public_ip
}

output "catapp_ip2" {
  value = aws_eip.hashicat2.*.public_ip
}

output "catapp_spot_ip" {
  value = aws_eip.hashicat_spot.*.public_ip
}

output "catapp_url" { 
  value = flatten(formatlist("http://%s", aws_eip.hashicat.*.public_dns))
}
output "catapp_url2" {
  value = flatten (formatlist("http://%s", aws_eip.hashicat2.*.public_dns))
}

output "catapp_spot_url" {
  value = flatten(formatlist("http://%s", aws_eip.hashicat_spot.*.public_dns))
}





#output "test"{
#  value=formatlist("cidr:%s/32", aws_eip.hashicat.*.public_ip)
#}
