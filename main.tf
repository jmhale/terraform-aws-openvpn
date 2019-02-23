data "aws_iam_policy_document" "openvpn_iampoldoc_buildartifacts" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::dogsec-build-artifacts",
      "arn:aws:s3:::dogsec-build-artifacts/*",
    ]
  }
}

data "aws_iam_policy_document" "ec2-assume-role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "openvpn_iampol_buildartifacts" {
  name        = "tf-openvpn-access-build-artifacts"
  description = "Terraform Managed. Allows OpenVPN to access build artifacts."
  policy      = "${data.aws_iam_policy_document.openvpn_iampoldoc_buildartifacts.json}"
}

resource "aws_iam_role" "openvpn_iamrole_buildartifacts" {
  name               = "tf-openvpn-access-build-artifacts"
  description        = "Terraform Managed. Allows OpenVPN to access build artifacts."
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.ec2-assume-role.json}"
}

resource "aws_iam_policy_attachment" "openvpn_iampolattach_buildartifacts" {
  name       = "openvpn_iampolattach_buildartifacts"
  roles      = ["${aws_iam_role.openvpn_iamrole_buildartifacts.name}"]
  policy_arn = "${aws_iam_policy.openvpn_iampol_buildartifacts.arn}"
}

resource "aws_iam_instance_profile" "openvpn_iamprofile_buildartifacts" {
  name = "tf-openvpn-access-build-artifacts"
  role = "${aws_iam_role.openvpn_iamrole_buildartifacts.name}"
}
