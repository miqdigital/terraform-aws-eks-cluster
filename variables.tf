variable "cluster-name" {
  description = "Enter eks cluster name - example like eks-frankfurt"
  type    = "string"
}

variable "eks-worker-ami" {
  default = "ami-02d5e7ca7bc498ef9"
  description = "eks worker node ami for eks cluster 1.13 - https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html"
}

# In eks worker node instance type directly affects the number of PODs can run on a Node. Choose wisely.
# https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt

variable "worker-node-instance_type" {
  description = "enter worker node instance type"
}

variable "ssh_key_pair" {
   description = "Enter SSH keypair name that already exist in the account"

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
