### This project is for the Devops Bootcamp Exercise for "Infrastructure as Code with Terraform"

1. `terraform init` and `terraform apply` to:
    - Create EKS cluster with 3 Nodes and 1 Fargate profile for java application
    - Deploy Mysql with 3 replicas with volumes for data persistence using helm (depends on EKS cluster and EBS CSI started)
1. Created a bucket on AWS S3 for shared Terraform state - enabled versioning and blocked all public access (left the default encryption type and disabled Bucket Key)
1. Configured Amazon S3 as remote storage for Terraform state in [providers.tf](providers.tf)
    - afterwards, to access remote state, ran `terraform init` and `terraform state list`
1. Created [Jenkinsfile](Jenkinsfile) to provision declared infrastructure by running terraform commands

##### EBS CSI Driver
Since K8s version 1.23 an additional driver is required to provision K8s storage in AWS. K8s volumes attach to cloud platform's storage - for AWS this means they attach to EBS volumes. The EBS CSI driver is responsible for handling EBS storage tasks and is not installed by default so without the installation of this driver, K8s volumes cannot be attached to storage in AWS. 

Processes on the node group nodes are responsible for creating and attaching these volumes. Because of that, we need to add a permissions policy to the node group so it can request these changes through AWS - this is defined as a managed AWS policy called: AmazonEBSCSIDriverPolicy, which we are attaching to the node groups.
