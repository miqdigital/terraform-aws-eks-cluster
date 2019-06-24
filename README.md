# Terraform-aws-eks-cluster
This repository showcases the terraform template that we use to setup our production ready EKS cluster on AWS. If you are looking to use EKS cluster on AWS then chances are high that you are already be having some sort of infrastructure on AWS and eventually be using VPC to create resources in. 

We have designed this template considering you have existing VPC `PRODVPC`. This `terraform` template creates new VPC for EKS cluster also lets you peer your existing VPC. This is done as a recommendatation and best practices suited for isolation.

# AWS EKS Architecture
![eks-architecture](https://user-images.githubusercontent.com/38158144/60009869-4052b880-9694-11e9-9580-bb76e6730503.png)

**Note** - Above architecture doesn't reflect all the components that are created by this template. However, it does give an idea about core infrastructure that will be created by this template. AWS resources that are created by this template listed below.

- Creates a new VPC with CIDR Block - 10.15.0.0/19 in Frankfurt region.
- Creates 3 public & 3 private subnets with each size of 4056 IP addresses in each zones (eu-central-1a, eu-central-1b and eu-central-1c)
- Creates recommened IAM service and EC2 roles required for EKS cluster.
- Create NAT Gateway.
- VPC peering connection.


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

#### Terraform Plan
```
$ terraform plan
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


