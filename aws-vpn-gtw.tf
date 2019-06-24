# create aws vpn gateway for EKS VPC Frankfurt
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = "${aws_vpc.frankfurt.id}"

  tags = "${
    map(
     "Name", "eks aws vpn gateway frankfurt"
    )
  }"
}
