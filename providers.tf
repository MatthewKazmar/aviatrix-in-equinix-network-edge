terraform {
  required_providers {
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = "~> 3.0.0"
    }
    equinix = {
      source = "equinix/equinix"
    }
    google = {
      source = "hashicorp/google"
    }
    aws = {
      source = "hashicorp/aws"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    ansible = {
      #  version = "~> 0.0.1"
      source = "ansible/ansible"
    }
  }
}