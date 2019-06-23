/**
 * Make AWS account ID available.
 *
 * This is added as an output so that other stacks can reference this. Usually
 * required for VPC peering.
 */

data "aws_caller_identity" "current" {}


/**
Adding VPC peering btw EKS Frankfurt VPC and your existing VPC in frankfurt region.
**/

resource "aws_vpc_peering_connection" "eks2prodvpc" {
  peer_owner_id = "${data.aws_caller_identity.current.account_id}"
  peer_vpc_id = "${var.prodvpc_id}" # variable.tf
  vpc_id = "${aws_vpc.frankfurt.id}"
  auto_accept = false
  peer_region = "us-east-1"

  accepter {
     allow_remote_vpc_dns_resolution = true
   }

  requester {
     allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Side = "Requester",
    Name = "EKS-Frankfurt"
  }
}


