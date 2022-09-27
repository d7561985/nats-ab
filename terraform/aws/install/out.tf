output "private_context_sys" {
  value = <<EOF
  nats context save ${var.domain}_sys --user ${var.SYS_ADMIN} --password ${var.sys_psw} --server "%{~ for i, v in var.private-ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "private_context_acc" {
  value = <<EOF
  nats context save${var.domain}_acc --user ${var.DOMAIN_ADMIN} --password ${var.acc_psw} --server "%{~ for i, v in var.private-ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "public_context_sys" {
  value = <<EOF
  nats context save ${var.domain}_sys --user ${var.SYS_ADMIN} --password ${var.sys_psw} --server "%{~ for i, v in var.public-ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "public_context_acc" {
  value = <<EOF
  nats context save${var.domain}_acc --user ${var.DOMAIN_ADMIN} --password ${var.acc_psw} --server "%{~ for i, v in var.public-ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}