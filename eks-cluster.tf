#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "frankfurt-cluster" {
  name = "terraform-eks-frankfurt-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "frankfurt-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.frankfurt-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "frankfurt-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.frankfurt-cluster.name}"
}

resource "aws_security_group" "frankfurt-cluster" {
  name        = "terraform-eks-frankfurt-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.frankfurt.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-frankfurt",
     "OWNER", "Devops",
     "PRODUCT", "EKS",
     "TEAM", "Devops",
    )
  }"
}

resource "aws_security_group_rule" "frankfurt-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.frankfurt-cluster.id}"
  source_security_group_id = "${aws_security_group.frankfurt-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "frankfurt-cluster-ingress-workstation-https" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.frankfurt-cluster.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "frankfurt" {

  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.frankfurt-cluster.arn}"
  version  = "${var.eks_version}"
  enabled_cluster_log_types = ["api", "audit", "scheduler", "controllerManager"]

  vpc_config {
    security_group_ids = ["${aws_security_group.frankfurt-cluster.id}"]
    subnet_ids         = ["${aws_subnet.frankfurt.*.id}", "${aws_subnet.frankfurt-private.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.frankfurt-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.frankfurt-cluster-AmazonEKSServicePolicy",
  ]
}
