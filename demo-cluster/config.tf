terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = "= 3.44.0"
  }


  ## change to your own backend 
  backend "s3" {
    bucket = "tfstatebucket-aberg"
    key    = "tf-project/ecs-anywhere-cluster/terraform.tfstate"
    region = "eu-central-1"
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
