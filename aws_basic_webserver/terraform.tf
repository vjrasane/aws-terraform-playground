
terraform {
  cloud {
    organization = "Ville"
    workspaces {
      name = "aws_basic_webserver"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}