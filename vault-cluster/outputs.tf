

output "catapp_ip" {
  value = aws_eip.vault.*.public_ip
}


