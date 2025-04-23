
terraform {
  cloud {
    organization = "Ville"
    workspaces {
      name = "eks"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
}