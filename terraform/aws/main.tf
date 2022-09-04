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

  INSTANCE_TYPE = "c5.large"
  SPOT_PRICE    = "0.99"
  names         = ["node1", "node2", "node3"]
  ports         = [4222, 4223, 7422, 4225, 7222, 8080]
}

module "cluster-spoke-1" {
  source      = "./init"
  ENVIRONMENT = "spoke-1"

  INSTANCE_TYPE = "c5.large"
  SPOT_PRICE    = "0.99"
  names         = ["spoke-1", "spoke-2", "spoke-3"]
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
  allprivate = concat(values(module.cluster-hub.private_ip), values(module.cluster-spoke-1.private_ip))
  allpub     = concat(values(module.cluster-hub.public_ip), values(module.cluster-spoke-1.public_ip))
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
      cluster_user : var.CLUSTER_USER,
      gw_user : var.GW_USER,
      protocols_pwd : random_string.protocols.result,
      cluster_nodes : {
        "cluster-leaf" : module.cluster-spoke-1.private_ip
      }
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/leaf.conf"
    content     = templatefile("${path.module}/cfg/leaf.cfg.tpl", {
      isLeaf : false,
      hub : [],
      leaf : "",
      sys_leaf : "",
      sys_psw : "",
      acc_psw : "",
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/account.conf"
    content     = templatefile("${path.module}/cfg/account.cfg.tpl", {
      sys_user : var.SYS_ADMIN,
      sys_leaf : var.SYS_LEAF,
      js_admin : var.DOMAIN_JS_ADMIN,
      admin : var.DOMAIN_ADMIN,
      client : var.DOMAIN_CLIENT,
      public : var.DOMAIN_PUBLIC,
      acc_psw : random_string.domain.result,
      sys_psw : random_string.sys.result,
      leaf : var.DOMAIN_LEAF,
    })
  }

  provisioner "file" {
    destination = "/etc/systemd/system/nats.service"
    content     = templatefile("${path.module}/cfg/nats.service", {
    })
  }

  provisioner "remote-exec" {
    inline = ["sudo systemctl restart nats"]
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
      cluster_user : var.CLUSTER_USER,
      protocols_pwd : random_string.protocols.result,
      gw_user : var.GW_USER,
      cluster_nodes : {
        "cluster-hub" : module.cluster-hub.private_ip
      }
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/leaf.conf"
    content     = templatefile("${path.module}/cfg/leaf.cfg.tpl", {
      hub : module.cluster-hub.private_ip,
      sys_leaf : var.SYS_LEAF,
      leaf : var.DOMAIN_LEAF,
      sys_psw : random_string.sys.result,
      acc_psw : random_string.domain.result,
      isLeaf : true,
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/account.conf"
    content     = templatefile("${path.module}/cfg/account.cfg.tpl", {
      sys_user : var.SYS_ADMIN,
      sys_leaf : var.SYS_LEAF,
      js_admin : var.DOMAIN_JS_ADMIN,
      admin : var.DOMAIN_ADMIN,
      client : var.DOMAIN_CLIENT,
      public : var.DOMAIN_PUBLIC,
      acc_psw : random_string.domain.result,
      sys_psw : random_string.sys.result,
      leaf : var.DOMAIN_LEAF,
    })
  }

  provisioner "file" {
    destination = "/etc/systemd/system/nats.service"
    content     = templatefile("${path.module}/cfg/nats.service", {
    })
  }

  provisioner "remote-exec" {
    inline = ["sudo systemctl restart nats"]
  }

  // why not started?
  #  provisioner "remote-exec" {
  #    inline =  ["screen -dmS new_screen nats-server -c ./cluster-hub.conf"]
  #  }

  depends_on = [module.cluster-hub, module.cluster-spoke-1]
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