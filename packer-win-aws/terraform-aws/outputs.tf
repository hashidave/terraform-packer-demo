output "windows_iteration" {
  value = data.hcp_packer_iteration.windows
}

output "windows_us_east_2" {
  value = data.hcp_packer_image.windows_us_east_2
}

output "catapp_url" { 
  value = aws_eip.WinServer.public_dns
}

output "catapp_ip" {
  value = aws_eip.WinServer.public_ip
}

