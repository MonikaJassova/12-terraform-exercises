terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "myapp-tf-exercises-tfstate-s3-bucket"
    key = "myapp/state.tfstate"
    region = "eu-central-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.1.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}
