variable "cluster-name" {
  default = "eks-frankfurt"
  type    = "string"
}

variable "public_subnets" {
    type    = "list"
    default = ["10.15.0.0/22", "10.15.4.0/22", "10.15.8.0/22"]
}

variable "private_subnets" {
    type    = "list"
    default = ["10.15.12.0/22", "10.15.16.0/22", "10.15.20.0/22"]
}

variable "aws_profile" {
  default = "eks"
  description = "configure AWS CLI profile"
}

variable "eks_version" {
   default = "1.13"
   description = "kubernetes cluster version provided by AWS EKS"

}

# update name to be peer vpc
variable "prodvpc-cidr-block" {
   description = "Enter CIDR range of the VPC you want EKS VPC to peer with"

}

variable "prodvpc_id" {
   description = "Enter VPC ID that you want EKS VPC to peer with"

}

variable "prodvpc-route-table-id" {
   description = "Enter routing table ID of the exiting VPC that you want EKS vpc to peer with"

}
