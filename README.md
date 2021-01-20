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
Create a new eks-worker-node-v1.tf file with different name and below changes you have to do for EKS cluster upgrade.
* Change the userdata name to new version(eks-worker-node-upgrade-v2.tf) and should not conflict with old one.
* Change the Launch configuration and autoscalling group name to new version and should not conflict with old one.
* Change the ami to which your going upgrade EKS version provided by AWS -- ##eks-worker-ami -- change to new version  
* In the new worker node file(eks-worker-node-upgrade-v2.tf), we have updated extra arguments for dedicated node(taint).
* Once you apply new .tf file and the new nodes will spin up , post that move workloads to the new one and delete old nodes.
* Please reffer eks-worker-node-upgrade-v2.tf file to upgrade the EKS cluster for reference and below steps to upgrade the worker nodes.

### Once you create new file and apply changes and also change the eks master version in .tf file.

```
$ terraform apply  
```
## Once changes have applied terraform files, it will show new nodes as well as old nodes with different version.

```
$ kubectl get no
  NAME                       STATUS   ROLES   AGE   VERSION
  ip-10-0-87-98.ec2.inetenal  Ready   <none>  21d   v1.12.7
  ip-10-0-15-24.ec2.inetenal  Ready   <none>  21d   v1.12.7
  ip-10-0-23-100.ec2.inetenal  Ready   <none>  21d   v1.13.7-eks-c57ff8
  ip-10-0-14-23.ec2.inetenal  Ready   <none>  21d   v1.13.7-eks-c57ff8
```
### The next step is update the kube-system components based on the versions compatibility and cordon the old nodes(should not schedule in the old nodes once you move the workloads)
```
$ kubectl cordon nodename (old nodes)
```
### Once you started draining the old nodes, the workload will move to the new node.

```
$ kubectl drain nodename (old nodes)

```
### Once the darining is completed for all the old nodes ,then delete the old nodes.

## Contribution
We are happy to accept the changes that you think can help the utilities grow.

Here are some things to note:

* Raise a ticket for any requirement
* Discuss the implementation requirement or bug fix with the team members
* Fork the repository and solve the issue in one single commit
* Raise a PR regarding the same issue and attach the required documentation or provide a more detailed overview of the changes


