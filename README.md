# tf-eks-foundation
Terraform modules for EKS base setup, including:
- Control plane
- IAM roles 
- Security groups

## Run with terraform

Update necessary variables and settings in terraform.tfvars following the sample file.

```
## Init the project
terraform init

## Download all remote modules
terrafrom get

## Prepare the output and verify
terraform plan

## Apply to AWS
terraform apply
```
