# to specify the terraform version
 
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.23.1"
    }
  }
}

#define the provider
provider "aws" {
  # Configuration options
  region = "us-east-1"
  
}