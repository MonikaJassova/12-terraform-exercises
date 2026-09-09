terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket = "myapp-tf-exercises-tfstate-obs-bucket"
    key    = "prometheus/terraform.tfstate"
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
  }
}

provider "opentelekomcloud" {
  region   = "eu-de"
  auth_url = "https://iam.eu-de.otc.t-systems.com/v3"
}
