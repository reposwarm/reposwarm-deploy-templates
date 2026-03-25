# --------------------------------------------------
# RepoSwarm — AWS ECS Fargate Deployment
# --------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "reposwarm/ecs/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "reposwarm"
      ManagedBy = "terraform"
    }
  }
}

locals {
  name_prefix = "reposwarm-${var.environment}"
}
