terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.5"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

module "cluster-hub" {
  source = "./init"

  ENVIRONMENT = "hub"

  INSTANCE_TYPE = "t3.medium"
  SPOT_PRICE    = "0.99"
  names         = ["node1", "node2"]
  ports         = [4222, 4223, 7422, 4225, 7222, 8080]
}

module "cluster-spoke-1" {
  source      = "./init"
  ENVIRONMENT = "spoke-1"

  INSTANCE_TYPE = "t3.medium"
  SPOT_PRICE    = "0.99"
  names         = ["spoke1-1", "spoke1-2"]
  ports         = [4222, 4223, 7422, 4225, 7222, 8080]
}

module "cluster-spoke-2" {
  source      = "./init"
  ENVIRONMENT = "spoke-2"

  INSTANCE_TYPE = "t3.medium"
  SPOT_PRICE    = "0.99"
  names         = ["spoke2-1", "spoke2-2"]
  ports         = [4222, 4223, 7422, 4225, 7222, 8080]
}

#
#module "cluster-spoke-2" {
#  source = "./init"
#
#  INSTANCE_TYPE = "r5d.2xlarge"
#  SPOT_PRICE = "0.99"
#  default = ["node1", "node2", "node3"]
#}

locals {
  allprivate = concat(concat(values(module.cluster-hub.private_ip), values(module.cluster-spoke-1.private_ip)), values(module.cluster-spoke-2.private_ip))
  allpub     = concat(concat(values(module.cluster-hub.public_ip), values(module.cluster-spoke-1.public_ip)), values(module.cluster-spoke-2.public_ip))
}

module "upload-hub" {
  source = "./install"
  domain = "hub"
  cluster = "cluster-hub"
  public-ip = merge(module.cluster-hub.public_ip)
  private-ip = merge(module.cluster-hub.private_ip)
  cluster-nodes = merge(module.cluster-hub.private_ip)

  cluster_pwd = random_string.protocols.result
  sys_psw = random_string.sys.result
  acc_psw = random_string.domain.result

  leaf = false

  depends_on = [module.cluster-hub]
}

module "upload-leaf" {
  source = "./install"
  domain = "leaf"
  cluster = "cluster-leaf"
  public-ip = merge(module.cluster-spoke-1.public_ip)
  private-ip = merge(module.cluster-spoke-1.private_ip)
  cluster-nodes = merge(module.cluster-spoke-1.private_ip)

  cluster_pwd = random_string.protocols.result
  sys_psw = random_string.sys.result
  acc_psw = random_string.domain.result

  leaf = true
  hub = module.cluster-hub.private_ip

  depends_on = [module.cluster-hub, module.cluster-spoke-1]
}

module "upload-leaf2" {
  source = "./install"
  domain = "leaf2"
  cluster = "cluster-leaf2"
  public-ip = merge(module.cluster-spoke-2.public_ip)
  private-ip = merge(module.cluster-spoke-2.private_ip)
  cluster-nodes = merge(module.cluster-spoke-2.private_ip)

  cluster_pwd = random_string.protocols.result
  sys_psw = random_string.sys.result
  acc_psw = random_string.domain.result

  leaf = true
  hub = module.cluster-hub.private_ip

  depends_on = [module.cluster-hub, module.cluster-spoke-2]
}

resource "random_string" "protocols" {
  length  = 16
  special = false
}

resource "random_string" "sys" {
  length  = 16
  special = false
}

resource "random_string" "domain" {
  length  = 16
  special = false
}