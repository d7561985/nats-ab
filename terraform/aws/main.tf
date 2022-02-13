terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

module "cluster-hub" {
  source = "./init"

  INSTANCE_TYPE = "r5d.2xlarge"
  SPOT_PRICE = "0.99"
  default = ["node1", "node2", "node3"]
}

module "cluster-spoke-1" {
  source = "./init"

  INSTANCE_TYPE = "r5d.2xlarge"
  SPOT_PRICE = "0.99"
  default = ["node1", "node2", "node3"]
}

module "cluster-spoke-2" {
  source = "./init"

  INSTANCE_TYPE = "r5d.2xlarge"
  SPOT_PRICE = "0.99"
  default = ["node1", "node2", "node3"]
}
