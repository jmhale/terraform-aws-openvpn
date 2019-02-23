# Output file
output "vpn_eip" {
  value = "${aws_eip.openvpn_eip.public_ip}"
}

output "vpn_sg_id" {
  value = "${aws_security_group.sg_openvpn_admin.id}"
}
