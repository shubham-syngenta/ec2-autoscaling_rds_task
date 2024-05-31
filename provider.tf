terraform {

  required_version = ">= 0.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

provider "aws" {
  region     = "us-east-1"

}

## For Route53
provider "aws" {
  alias = "dns-account"
  assume_role {
    role_arn = "<ROUTE53AccountRole>" #can't add accountid due to security reasons
  }
}