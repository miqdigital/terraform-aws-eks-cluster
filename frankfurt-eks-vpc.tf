#
# EKS VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "frankfurt" {
  cidr_block = "10.15.0.0/19"
  enable_dns_hostnames = true

  tags = "${
    map(
     "Name", "frankfurt-eks-vpc",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

## EKS public subnets
resource "aws_subnet" "frankfurt" {
  count = "${length(var.public_subnets)}"

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.public_subnets[count.index]}"
  vpc_id            = "${aws_vpc.frankfurt.id}"

  tags = "${
    map(
     "Name", "frankfurt-eks-public-subnet",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}


## internet gateway
resource "aws_internet_gateway" "frankfurt" {
  vpc_id = "${aws_vpc.frankfurt.id}"

  tags {
    Name = "frankfurt-eks-frankfurt"
  }
}

resource "aws_route_table" "frankfurt" {
  vpc_id = "${aws_vpc.frankfurt.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.frankfurt.id}"
  }

## route for vpc peering with prod vpc. ##
#  route {
#    cidr_block = "${var.prodvpc-cidr-block}" # variables.tf
#    vpc_peering_connection_id = "${aws_vpc_peering_connection.eks2prodvpc.id}"
#  }
#

}

resource "aws_route_table_association" "frankfurt" {
  count = "${length(var.public_subnets)}"

  subnet_id      = "${aws_subnet.frankfurt.*.id[count.index]}"
  route_table_id = "${aws_route_table.frankfurt.id}"
}

## EKS private subnets
## NAT gateway
## routing table, routing table association

resource "aws_subnet" "frankfurt-private" {
  count = "${length(var.private_subnets)}"

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.private_subnets[count.index]}"
  vpc_id            = "${aws_vpc.frankfurt.id}"

  tags = "${
    map(
     "Name", "frankfurt-eks-private-subnet",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
     "kubernetes.io/role/internal-elb", "1",
     "TEAM", "Devops",
     "PRODUCT", "EKS",
     
    )
  }"
}

resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  count = 1
  
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.frankfurt.*.id[count.index]}"  #public subnet 
  depends_on = ["aws_internet_gateway.frankfurt"]

  tags {
    Name = "gw NAT"
  }
}


resource "aws_route_table" "frankfurt-private" {
  vpc_id = "${aws_vpc.frankfurt.id}"

  tags {
        Name = "route table for private subnets",
        TEAM = "Devops",
        PRODUCT = "EKS",
        ENVIRONMENT = "PROD",
    }
}

resource "aws_route_table_association" "frankfurt-private" {
  count = "${length(var.private_subnets)}"

  subnet_id      = "${aws_subnet.frankfurt-private.*.id[count.index]}"
  route_table_id = "${aws_route_table.frankfurt-private.id}"
}
