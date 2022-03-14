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

  INSTANCE_TYPE = "c5.2xlarge"
  SPOT_PRICE    = "0.99"
  names         = ["node1", "node2"]
  ports         = [4222, 4223, 4224, 4225, 8080]
}

module "cluster-spoke-1" {
  source      = "./init"
  ENVIRONMENT = "spoke-1"

  INSTANCE_TYPE = "c5.2xlarge"
  SPOT_PRICE    = "0.99"
  names         = ["spoke-1", "spoke-2"]
  ports         = [4222, 4223, 4224, 4225, 8080]
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
  leafConf    = "leaf.conf"
  leafUser    = "leaf_user"
  leafPsw     = "leaf_psw"
  clusterUser = "cluster_user"
  clusterPsw  = "cluster_psw"
  testUser    = "test"
  testPsw     = "test"
  gw_user     = "test"
  gw_psw      = "test"
  allprivate  = concat(values(module.cluster-hub.private_ip), values(module.cluster-spoke-1.private_ip))
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
      host : each.value,
      nodes : module.cluster-hub.private_ip,
      domain : "hub",
      cluster : "cluster-hub",
      leafConf : local.leafConf,
      cluster_user : local.clusterUser,
      cluster_psw : local.clusterPsw,
      sys_user : var.sys_user,
      sys_psw : var.sys_psw,
      acc_user : var.acc_user,
      acc_psw : var.acc_psw,
      gw_user: local.gw_user,
      gw_psw: local.gw_psw,
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/${local.leafConf}"
    content     = templatefile("${path.module}/cfg/leaf.cfg.tpl", {
      isLeaf : false,
      hub : [],
      sys_user : "",
      sys_psw : "",
      acc_user : "",
      acc_psw : "",
    })
  }

  #  provisioner "remote-exec" {
  #    inline =  ["screen -dmS new_screen nats-server -c ./cluster-hub.conf"]
  #  }

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
      host : each.value,
      nodes : module.cluster-spoke-1.private_ip,
      domain : "leaf",
      cluster : "cluster-leaf",
      leafConf : local.leafConf,
      cluster_user : local.clusterUser,
      cluster_psw : local.clusterPsw,
      sys_user : var.sys_user,
      sys_psw : var.sys_psw,
      acc_user : var.acc_user,
      acc_psw : var.acc_psw,
      gw_user: local.gw_user,
      gw_psw: local.gw_psw,
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/${local.leafConf}"
    content     = templatefile("${path.module}/cfg/leaf.cfg.tpl", {
      hub : module.cluster-hub.private_ip,
      sys_user : var.sys_user,
      sys_psw : var.sys_psw,
      acc_user : var.acc_user,
      acc_psw : var.acc_psw,
      isLeaf : true,
    })
  }

  // why not started?
  #  provisioner "remote-exec" {
  #    inline =  ["screen -dmS new_screen nats-server -c ./cluster-hub.conf"]
  #  }

  depends_on = [module.cluster-hub, module.cluster-spoke-1]
}