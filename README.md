# Introduction
This repository showcases the terraform template that will help you to create EKS cluster on AWS. 

---

# AWS EKS Architecture
![github_eks](https://user-images.githubusercontent.com/38158144/60167519-e29fa700-9820-11e9-9ecc-86be99973cd7.png)

**Note** - Above architecture doesn't reflect all the components that are created by this template. However, it does give an idea about core infrastructure that will be created. 

- Creates a new VPC with CIDR Block - 10.15.0.0/19 (i.e 8190 IPs in a VPC) in a region of your choice. Feel free to change it, values are `variables.tf`.
- Creates 3 public & 3 private subnets with each size of 1024 IP addresses in each zones
- Creates security groups required for cluster and worker nodes.
- Creates recommened IAM service and EC2 roles required for EKS cluster.
- Creates Internet & NAT Gateway required for public and private communications.
- Routing Table and routes for public and private subnets.


### Before you start
Before you execute this template make sure following dependencies are met.

- [Install terraform](https://releases.hashicorp.com/terraform/0.11.13/)
- [Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-linux-al2017.html) - make sure you configure AWS CLI with admin previliges 
- [AWS iam authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) - Amazon EKS uses IAM to provide authentication to your Kubernetes cluster through the AWS IAM Authenticator for Kubernetes.


### Setup
```
$ git clone https://github.com/MediaIQ/terraform-aws-eks-cluster.git
$ cd terraform-aws-eks-cluster
```

#### Initialize Terraform
```
$ terraform init
```

#### Terraform Plan
The terraform plan command is used to create an execution plan. Always a good practice to run it before you apply it to see what all resources will be created.

This will ask you to specify `cluster name` and worker node instance type. 

```
$ terraform plan

var.cluster-name
  Enter eks cluster name - example like eks-demo, eks-dev etc

  Enter a value: eks-demo

var.region
  Enter region you want to create EKS cluster in

  Enter a value: us-east-1

var.ssh_key_pair
  Enter SSH keypair name that already exist in the account

  Enter a value: eks-keypair

var.worker-node-instance_type
  enter worker node instance type

  Enter a value: t2.medium

```

#### Apply changes
```
$ terraform apply
```

#### Configure kubectl
```
$ aws eks --region <AWS-REGION> update-kubeconfig --name <CLUSTER-NAME>
```
**Note:-** If AWS CLI and AWS iam authenticator setup correctly, above command should setup kubeconfig file in ~/.kube/config in your system.

#### Verify EKS cluster
```
$ kubectl get svc
```

**Output:**
```
NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
svc/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   1m
```

Once cluster is verified succesfully, its time to create a configMap to add the worker nodes into the cluster. We have configured `output` with this template which will produce the configMap file content that you paste in *`aws-auth.yaml`*.

#### Add worker node
```
$ kubectl apply -f aws-auth.yaml
```

#### Nodes status - watch them joining the cluster
```
$ kubectl get no -w
```
**Note:-** You should be seeing nodes joining the cluster within less than minutes.

---
#### EKS cluster upgrade using new asg file in terraform
Create a new eks-worker-node.tf file with different name and below changes you have to do for EKS cluster upgrade.
* Change the userdata name to new one.
* Change the Launch configuration and autoscalling group name to new one.
* Change the ami to which your going upgrade EKS version provided by AWS -- ##eks-worker-ami -- change to new version  
* And in the new worker node file we have updated how to use taint for dedicated node.
* Once you apply new tf file the new nodes will spinn up and move the workload to the new one and delete old nodes.
* Please reffer eks-worker-node-new.tf file to upgrade the EKS cluster for reference.


## Contribution
We are happy to accept the changes that you think can help the utilities grow.

Here are some things to note:

* Raise a ticket for any requirement
* Discuss the implementation requirement or bug fix with the team members
* Fork the repository and solve the issue in one single commit
* Raise a PR regarding the same issue and attach the required documentation or provide a more detailed overview of the changes


