terraform {
  required_version = ">= 1.3"

  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "~> 1.37.0"
    }
  }
}
