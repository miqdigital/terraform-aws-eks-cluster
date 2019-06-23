## A "backend" in Terraform determines how state is loaded. Its completely optional but recommended.
## Terraform remote state management - visit https://www.terraform.io/docs/backends/index.html
## eks-frankfurt is the folder inside the bucket that you are going to choose to store terraform state files. 
## make sure you create it in advance.

terraform {
  backend "s3" {
    bucket = "{var.s3_bucket_name}"
    key    = "eks-frankfurt/terraform.tfstate"
    region = "us-east-1"
  }
}
