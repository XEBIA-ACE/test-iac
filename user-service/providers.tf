terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67"
    }
  }

  backend "s3" {
    bucket         = "shopping-app-tfstate-user-svc"
    key            = "user-service/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "shopping-app-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "ace"
      Environment = var.environment
      Project     = var.project_id
      Service     = "user-service"
      ServiceId   = "SVC-01"
      OrgId       = var.org_id
    }
  }
}