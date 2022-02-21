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

  ENVIRONMENT = "hub"

#  INSTANCE_TYPE = "r5d.2xlarge"
  SPOT_PRICE = "0.99"
  names = ["node1", "node2"]
  ports = [4222, 4223, 4224, 4225, 8080]
}

module "cluster-spoke-1" {
  source = "./init"
  ENVIRONMENT = "spoke-1"

  # INSTANCE_TYPE = "r5d.2xlarge"
  SPOT_PRICE = "0.99"
  names = ["spoke-1", "spoke-2"]
  ports = [4222, 4223, 4224, 4225, 8080]
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
  leafConf= "leaf.conf"
}

resource "null_resource" "upload-hub" {
  for_each = merge(module.cluster-hub.public_ip)

  connection {
    type  = "ssh"
    user  = "ec2-user"
    host  = each.value
    agent = true
  }

  provisioner "file" {
    destination = "/home/ec2-user/cluster-hub.conf"
    content     = templatefile("${path.module}/cfg/cluster-hub.cfg.tpl", {
      host: each.value,
      nodes: module.cluster-hub.private_ip,
      domain: "hub",
      isHub: true,
      leafConf: local.leafConf,
    })
  }

  depends_on = [module.cluster-hub]
}

resource "null_resource" "upload-leaf" {
  for_each = merge(module.cluster-spoke-1.public_ip)

  connection {
    type  = "ssh"
    user  = "ec2-user"
    host  = each.value
    agent = true
  }

  provisioner "file" {
    destination = "/home/ec2-user/cluster-hub.conf"
    content     = templatefile("${path.module}/cfg/cluster-hub.cfg.tpl", {
      host: each.value,
      nodes: module.cluster-hub.private_ip,
      domain: "hub",
      isHub: false,
      leafConf: local.leafConf,
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/${local.leafConf}"
    content     = templatefile("${path.module}/cfg/leaf.cfg.tpl", {
      hub: module.cluster-hub.private_ip,
    })
  }

  depends_on = [module.cluster-hub, module.cluster-spoke-1]
}
