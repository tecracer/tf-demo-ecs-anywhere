terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = "= 3.44.0"
  }

  backend "local" {
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "trc:environment" = "ecs-anywhere-test"
      "trc:managedBy"   = "Terraform"
      "trc:project"     = "Fun with ECS Anywhere"
    }
  }
}
