#
# EKS VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "eks" {
  cidr_block = "10.15.0.0/19"
  enable_dns_hostnames = true

  tags = "${
    map(
     "Name", "eks-vpc",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

## EKS public subnets
resource "aws_subnet" "eks-public" {
  count = "${length(var.public_subnets)}"

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.public_subnets[count.index]}"
  vpc_id            = "${aws_vpc.eks.id}"

  tags = "${
    map(
     "Name", "eks-public-subnet",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}


## internet gateway
resource "aws_internet_gateway" "eks-igw" {
  vpc_id = "${aws_vpc.eks.id}"

  tags {
    Name = "eks-internet-gateway"
  }
}

resource "aws_route_table" "eks-public" {
  vpc_id = "${aws_vpc.eks.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks-igw.id}"
  }

}

resource "aws_route_table_association" "eks" {
  count = "${length(var.public_subnets)}"

  subnet_id      = "${aws_subnet.eks-public.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks-public.id}"
}

## EKS private subnets
## NAT gateway
## routing table, routing table association

resource "aws_subnet" "eks-private" {
  count = "${length(var.private_subnets)}"

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.private_subnets[count.index]}"
  vpc_id            = "${aws_vpc.eks.id}"

  tags = "${
    map(
     "Name", "eks-private-subnet",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
     "kubernetes.io/role/internal-elb", "1", 
    )
  }"
}

resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_nat_gateway" "nat_gw" {
  count = 1
  
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.eks-public.*.id[count.index]}"  #public subnet 
  depends_on = ["aws_internet_gateway.eks-igw"]

  tags {
    Name = "gw NAT"
  }
}


resource "aws_route_table" "eks-private" {
  vpc_id = "${aws_vpc.eks.id}"

  tags {
        Name = "route table for private subnets"
    }
}

resource "aws_route_table_association" "eks-private" {
  count = "${length(var.private_subnets)}"

  subnet_id      = "${aws_subnet.eks-private.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks-private.id}"
}
