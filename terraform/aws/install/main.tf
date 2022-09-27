resource "null_resource" "upload-hub" {
  for_each = var.public-ip

  connection {
    type  = "ssh"
    user  = "ec2-user"
    host  = each.value
    agent = true
  }

  provisioner "file" {
    destination = "/home/ec2-user/server.conf"
    content     = templatefile("${path.module}/cfg/cluster-hub.cfg.tpl", {
      host : each.value,
      nodes : var.private-ip,
      domain : var.domain,
      cluster : var.cluster,
      cluster_user : var.CLUSTER_USER,
      gw_user : var.GW_USER,
      protocols_pwd : var.cluster_pwd,
      cluster_nodes : {
        "cluster-leaf" : var.cluster-nodes
      }
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/leaf.conf"
    content     = templatefile("${path.module}/cfg/leaf.cfg.tpl", {
      isLeaf : var.leaf,
      hub : var.hub,

      sys_leaf : var.SYS_LEAF,
      sys_psw : var.sys_psw,

      leaf : var.DOMAIN_LEAF,
      acc_psw : var.acc_psw,
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/account.conf"
    content     = templatefile("${path.module}/cfg/account.cfg.tpl", {
      sys_user : var.SYS_ADMIN,
      js_admin : var.DOMAIN_JS_ADMIN,
      admin : var.DOMAIN_ADMIN,
      client : var.DOMAIN_CLIENT,

      public : var.DOMAIN_PUBLIC,

      sys_leaf : var.SYS_LEAF,
      sys_psw : var.sys_psw,

      leaf : var.DOMAIN_LEAF,
      acc_psw : var.acc_psw,
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/nats.service"
    content     = templatefile("${path.module}/cfg/nats.service", {
    })
  }

  provisioner "file" {
    destination = "/home/ec2-user/userdata.sh"
    content     = file("${path.module}/cfg/userdata.sh")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 ./userdata.sh && ./userdata.sh",
      "sudo cp /home/ec2-user/nats.service /etc/systemd/system/nats.service",
      "sudo systemctl restart nats"
    ]
  }


  #  provisioner "remote-exec" {
  #    inline =  ["screen -dmS new_screen nats-server -c ./cluster-hub.conf"]
  #  }

}
