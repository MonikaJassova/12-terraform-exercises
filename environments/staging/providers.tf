terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket = "myapp-tf-exercises-tfstate-obs-bucket"
    key    = "staging/terraform.tfstate"
    region = "eu-de"
    endpoints = {
      s3 = "https://obs.eu-de.otc.t-systems.com/"
    }
    use_path_style              = true
    use_lockfile                = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }

  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "~> 1.37.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
  }
}

provider "opentelekomcloud" {
  region      = "eu-de"
  auth_url    = "https://iam.eu-de.otc.t-systems.com/v3"
  domain_name = "OTC-EU-DE-00000000001000047542"
  tenant_name = "eu-de_mjassova"
}

locals {
  kubeconfig = jsondecode(module.base.kubeconfig)
}

provider "helm" {
  kubernetes = {
    host               = "https://${module.base.cluster_eip}:5443"
    insecure           = true
    client_certificate = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
    client_key         = base64decode(local.kubeconfig.users[0].user["client-key-data"])
  }
}
