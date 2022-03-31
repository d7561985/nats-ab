output "public_ip" {
  depends_on = [module.cluster-hub]
  value = module.cluster-hub.public_ip
}

output "spoke-1-public_ip" {
  depends_on = [module.cluster-spoke-1]

  value = module.cluster-spoke-1.public_ip
}

output "private_context_sys" {
  depends_on = [module.cluster-hub, module.cluster-spoke-1]
  value = <<EOF
  nats context save sys --user ${var.SYS_ADMIN} --password ${random_string.sys.result} --server "%{~ for i, v in local.allprivate ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "private_context_hub" {
  depends_on = [module.cluster-hub]
  value = <<EOF
  nats context save hub --user ${var.DOMAIN_CLIENT} --password ${random_string.domain.result} --server "%{~ for i, v in module.cluster-hub.private_ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "private_context_spoke_1" {
  depends_on = [module.cluster-spoke-1]
  value = <<EOF
  nats context save spoke-1 --user ${var.DOMAIN_CLIENT} --password ${random_string.domain.result} --server "%{~ for i, v in module.cluster-spoke-1.private_ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "public_context_sys" {
  depends_on = [module.cluster-hub, module.cluster-spoke-1]
  value = <<EOF
  nats context save sys --user ${var.SYS_ADMIN} --password ${random_string.sys.result} --server "%{~ for i, v in local.allpub ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "public_context_hub" {
  depends_on = [module.cluster-hub]
  value = <<EOF
  nats context save hub --user ${var.DOMAIN_CLIENT} --password ${random_string.sys.result} --server "%{~ for i, v in module.cluster-hub.public_ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "public_context_spoke_1" {
  depends_on = [module.cluster-spoke-1]
  sensitive = true
  value = <<EOF
  nats context save spoke-1 --user ${var.DOMAIN_CLIENT} --password ${random_string.sys.result} --server "%{~ for i, v in module.cluster-spoke-1.public_ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}