# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml

## updated AMI support for /etc/eks/bootstrap.sh
##

resource "aws_security_group" "frankfurt-node" {
  name        = "terraform-eks-frankfurt-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.frankfurt.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-frankfurt-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
     "OWNER", "Devops",
     "PRODUCT", "EKS",
     "TEAM", "Devops",
    )
  }"
}

resource "aws_security_group_rule" "frankfurt-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.frankfurt-node.id}"
  source_security_group_id = "${aws_security_group.frankfurt-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "frankfurt-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.frankfurt-node.id}"
  source_security_group_id = "${aws_security_group.frankfurt-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

# HPA requires 443 to be open for k8s control plane.
resource "aws_security_group_rule" "frankfurt-node-ingress-hpa" {
  description              = "Allow HPA to receive communication from the cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.frankfurt-node.id}"
  source_security_group_id = "${aws_security_group.frankfurt-cluster.id}"
  to_port                  = 443
  type                     = "ingress"
}

# automatically allowing ssh on worker nodes from localwork station MYIP
resource "aws_security_group_rule" "frankfurt-cluster-ingress-workstation-ssh" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to ssh on worker nodes"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.frankfurt-cluster.id}"
  to_port           = 22
  type              = "ingress"
}


#### User data for worker launch

locals {
  frankfurt-node-private-userdata = <<USERDATA
#!/bin/bash -xe

yum install -y curl unzip perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64

curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
unzip CloudWatchMonitoringScripts-1.2.2.zip
rm CloudWatchMonitoringScripts-1.2.2.zip

echo '* * * * * /aws-scripts-mon/mon-put-instance-data.pl -mem-util --auto-scaling=only' > /tmp/mycrontab.txt
crontab -u ec2-user /tmp/mycrontab.txt

sudo /etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.frankfurt.endpoint}' --b64-cluster-ca '${aws_eks_cluster.frankfurt.certificate_authority.0.data}' '${var.cluster-name}'

USERDATA
}

resource "aws_launch_configuration" "frankfurt-private" {
  iam_instance_profile        = "${aws_iam_instance_profile.frankfurt-node.name}"
  image_id                    = "ami-0c2709025eb548246" # eu-central-1 version 1.11.8
  instance_type               = "r5.xlarge"
  key_name                    = "rancher"
  name_prefix                 = "terraform-eks-frankfurt-private"
  security_groups             = ["${aws_security_group.frankfurt-node.id}"]
  user_data_base64            = "${base64encode(local.frankfurt-node-private-userdata)}"
  
  root_block_device {
    delete_on_termination = true
    volume_size = 200
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "frankfurt-private" {
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.frankfurt-private.id}"
  max_size             = 5
  min_size             = 1
  name                 = "terraform-eks-frankfurt-private"
  vpc_zone_identifier  = ["${aws_subnet.frankfurt-private.*.id}"]

  tag {
    key                 = "Name"
    value               = "eks-worker-private-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster-name}"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "TEAM"
    value               = "Devops"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "OWNER"
    value               = "Devops"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "PRODUCT"
    value               = "EKS"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "ENVIRONMENT"
    value               = "PROD"
    propagate_at_launch = true
  }

}


# Adding EKS workers scaling policy for scale up/down 
# Creating Cloudwatch alarms for both scale up/down 

resource "aws_autoscaling_policy" "eks-cpu-policy-private" {
  name = "eks-cpu-policy-private"
  autoscaling_group_name = "${aws_autoscaling_group.frankfurt-private.name}"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = "300"
  policy_type = "SimpleScaling"
}

# scaling up cloudwatch metric
resource "aws_cloudwatch_metric_alarm" "eks-cpu-alarm-private" {
  alarm_name = "eks-cpu-alarm-private"
  alarm_description = "eks-cpu-alarm-private"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "80"

dimensions = {
  "AutoScalingGroupName" = "${aws_autoscaling_group.frankfurt-private.name}"
}
  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.eks-cpu-policy-private.arn}"]
}

# scale down policy
resource "aws_autoscaling_policy" "eks-cpu-policy-scaledown-private" {
  name = "eks-cpu-policy-scaledown-private"
  autoscaling_group_name = "${aws_autoscaling_group.frankfurt-private.name}"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "-1"
  cooldown = "300"
  policy_type = "SimpleScaling"
}

# scale down cloudwatch metric
resource "aws_cloudwatch_metric_alarm" "eks-cpu-alarm-scaledown-private" {
  alarm_name = "eks-cpu-alarm-scaledown-private"
  alarm_description = "eks-cpu-alarm-scaledown-private"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "5"

dimensions = {
  "AutoScalingGroupName" = "${aws_autoscaling_group.frankfurt-private.name}"
}
  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.eks-cpu-policy-scaledown-private.arn}"]
}


####
#### Memory based scaling alarm and scaling policies
####

## scale up policy for eks node memory usage.
resource "aws_autoscaling_policy" "eks-mem-policy-private" {
  name = "eks-mem-policy-private"
  autoscaling_group_name = "${aws_autoscaling_group.frankfurt-private.name}"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = "300"
  policy_type = "SimpleScaling"
}

## Cloudwatch alarm for avg memory utlization
resource "aws_cloudwatch_metric_alarm" "eks-mem-alarm-private" {
  alarm_name = "eks-mem-alarm-private"
  alarm_description = "eks-mem-alarm-private"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "5"
  metric_name = "MemoryUtilization"
  namespace = "System/Linux"
  period = "60"
  statistic = "Average"
  threshold = "80"

dimensions = {
  "AutoScalingGroupName" = "${aws_autoscaling_group.frankfurt-private.name}"
}
  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.eks-mem-policy-private.arn}"]
}
