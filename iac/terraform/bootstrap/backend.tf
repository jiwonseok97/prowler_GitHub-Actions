terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket         = "prowler-terraform-state-132410971304"
    key            = "bootstrap/iam-permissions.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "prowler-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-northeast-2"
}
