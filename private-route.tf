resource "aws_route" "nat_gtw" {
 route_table_id = "${aws_route_table.frankfurt-private.id}"
 destination_cidr_block = "0.0.0.0/0"
 nat_gateway_id = "${aws_nat_gateway.gw.id}"    
}


resource "aws_route" "eks2prodvpc" {
 route_table_id = "${aws_route_table.frankfurt-private.id}"
 destination_cidr_block = "${var.prodvpc-cidr-block}"
 vpc_peering_connection_id = "${aws_vpc_peering_connection.eks2prodvpc.id}"

}

resource "aws_route" "prodvpc2eks" {
 route_table_id = "${var.prodvpc-route-table-id}"
 destination_cidr_block = "${aws_vpc.frankfurt.cidr_block}"
 vpc_peering_connection_id = "${aws_vpc_peering_connection.eks2prodvpc.id}"

}


