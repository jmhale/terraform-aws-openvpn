resource "aws_security_group" "sg_openvpn_external" {
  name        = "openvpn-external"
  description = "Terraform Managed. Allow VPN client traffic from external."
  vpc_id      = "${var.vpc_id}"

  tags {
    Name       = "openvpn-external"
    Project    = "vpn"
    tf-managed = "True"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_openvpn_admin" {
  name        = "openvpn-admin"
  description = "Terraform Managed. Allow admin traffic to internal resources from VPN"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name       = "openvpn-admin"
    Project    = "vpn"
    tf-managed = "True"
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.sg_openvpn_external.id}"]
  }

  ingress {
    from_port       = 8
    to_port         = 0
    protocol        = "icmp"
    security_groups = ["${aws_security_group.sg_openvpn_external.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "openvpn_instance" {
  ami                    = "${var.ami_id}"
  instance_type          = "t2.micro"
  key_name               = "${var.ssh_key_id}"
  subnet_id              = "${var.public_subnet_ids[0]}"
  vpc_security_group_ids = ["${aws_security_group.sg_openvpn_external.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.openvpn_iamprofile_buildartifacts.name}"

  user_data = <<EOF
#!/bin/bash
apt-get update
apt-get upgrade -y
apt-get install -y openvpn easy-rsa awscli
aws configure set s3.signature_version s3v4
aws s3 sync s3://dogsec-build-artifacts/openvpn /etc/openvpn
mv /etc/openvpn/before.rules /etc/ufw/before.rules
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw
mv /etc/openvpn/sysctl.conf /etc/sysctl.conf
sysctl -p
ufw allow ssh
ufw allow https
ufw --force enable
systemctl enable openvpn@server
systemctl start openvpn@server
EOF

  tags {
    Name       = "openvpn"
    Project    = "vpn"
    tf-managed = "True"
  }
}

resource "aws_eip" "openvpn_eip" {
  instance = "${aws_instance.openvpn_instance.id}"
  vpc      = true
}
