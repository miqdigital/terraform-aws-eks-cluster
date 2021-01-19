# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml

## updated AMI support for /etc/eks/bootstrap.sh
#### User data for worker launch

locals {
  eks-node-private-userdata-new = <<USERDATA
#!/bin/bash -xe

sudo /etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster-name}' \
--kubelet-extra-args "--node-labels=app=name --register-with-taints=app=name:NoExecute --kube-reserved cpu=500m,memory=1Gi,ephemeral-storage=1Gi --system-reserved cpu=500m,memory=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%"

USERDATA
}

resource "aws_launch_configuration" "eks-private-lc-new" {
  iam_instance_profile        = "${aws_iam_instance_profile.eks-node.name}"
  image_id                    = "${var.eks-worker-ami}" ## update to th bew version of ami --visit https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  instance_type               = "${var.worker-node-instance_type}" # use instance variable
  key_name                    = "${var.ssh_key_pair}"
  name_prefix                 = "eks-private"
  security_groups             = ["${aws_security_group.eks-node.id}"]
  user_data_base64            = "${base64encode(local.eks-node-private-userdata-new)}"
  
  root_block_device {
    delete_on_termination = true
    volume_size = 30
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks-private-asg-new" {
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.eks-private-lc-new.id}"
  max_size             = 2
  min_size             = 1
  name                 = "eks-private"
  vpc_zone_identifier  = ["${aws_subnet.eks-private.*.id}"]

  tag {
    key                 = "Name"
    value               = "eks-worker-private-node-new"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }

## Enable this when you use cluster autoscaler within cluster.
## https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md

#  tag {
#    key                 = "k8s.io/cluster-autoscaler/enabled"
#    value               = ""
#    propagate_at_launch = true
#  }
#
#  tag {
#    key                 = "k8s.io/cluster-autoscaler/${var.cluster-name}"
#    value               = ""
#    propagate_at_launch = true
#  }

}


# Adding EKS workers scaling policy for scale up/down 
# Creating Cloudwatch alarms for both scale up/down 
If require you can use scale up/down policy or else cluster autoscaler will take of scalling the node.