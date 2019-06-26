# Introduction
This repository showcases the terraform template that will help you to create EKS cluster on AWS. 

We have designed this template considering you have existing VPC `PRODVPC`. This `terraform` template creates new VPC for EKS cluster also lets you peer your existing VPC. This is done as a recommendatation and best practices suited for isolation.

---

# AWS EKS Architecture
![github_eks](https://user-images.githubusercontent.com/38158144/60167519-e29fa700-9820-11e9-9ecc-86be99973cd7.png)

**Note** - Above architecture doesn't reflect all the components that are created by this template. However, it does give an idea about core infrastructure that will be created by this template. AWS resources that are created by this template listed below.

- Creates a new VPC with CIDR Block - 10.15.0.0/19 (i.e 8190 IPs in a VPC)in Frankfurt region. You may want to change it, values are `variables.tf`.
- Creates 3 public & 3 private subnets with each size of 1024 IP addresses in each zones (eu-central-1a, eu-central-1b and eu-central-1c
- Creates security groups required for cluster and worker nodes.
- Creates recommened IAM service and EC2 roles required for EKS cluster.
- Creates Internet & NAT Gateway required for public and private communications.
- Routing Table and routes for public and private subnets.


### Before you start
Before you execute this template make sure following dependencies are met.

- Install terraform
- Configure AWS CLI (make sure you have admin privileges - IAM admin access)
- AWS iam authenticator


### Setup
```
$ git clone <REPO>
$ cd <FOLDER>
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
  Enter eks cluster name - example like eks-frankfurt

  Enter a value: eks-frankfurt

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
$ aws eks --region eu-central-1 update-kubeconfig --name <CLUSTER-NAME>
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

## Contribution
We are happy to accept the changes that you think can help the utilities grow.

Here are some things to note:

* Raise a ticket for any requirement
* Discuss the implementation requirement or bug fix with the team members
* Fork the repository and solve the issue in one single commit
* Raise a PR regarding the same issue and attach the required documentation or provide a more detailed overview of the changes


