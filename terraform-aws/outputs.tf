output "ubuntu_iteration" {
  value = data.hcp_packer_iteration.ubuntu
}

output "ubuntu_us_east_2" {
  value = data.hcp_packer_image.ubuntu_us_east_2
}

output "catapp_url" { 
  value = aws_eip.hashicat.*.public_dns
}

output "ssh_private_key"{
  value=var.ssh_private_key
  sensitive=true
}


output "catapp_ip" {
  value = aws_eip.hashicat.*.public_ip
}

#output "catapp_url2" {
#  value = "http://" + {aws_eip.hashicat2.*.public_dns}
#}

output "catapp_ip2" {
  value = "http://${aws_eip.hashicat2.*.public_ip}"
}

#output "catapp_spot_url" {
#  value = "http://${aws_eip.hashicat_spot.*.public_dns}"
#}

#output "catapp_spot_ip" {
#  value = "http://${aws_eip.hashicat_spot.*.public_ip}"
#}
