# create aws vpn gateway for EKS VPC
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = "${aws_vpc.eks.id}"

  tags = "${
    map(
     "Name", "eks aws vpn gateway"
    )
  }"
}
