terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.26.0"
    }
  }
  cloud {
    organization = "learning_jig"
    workspaces {
        name = "EC2"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}