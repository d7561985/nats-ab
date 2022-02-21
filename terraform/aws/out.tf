output "public_ip" {
  depends_on = [module.cluster-hub]
  value = module.cluster-hub.public_ip
}

output "spoke-1-public_ip" {
  depends_on = [module.cluster-spoke-1]

  value = module.cluster-spoke-1.public_ip
}

output "context_sys" {
  depends_on = [module.cluster-hub, module.cluster-spoke-1]
  value = <<EOF
  nats context save sys --server "%{~ for i, v in local.allprivate ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "context_hub" {
  depends_on = [module.cluster-hub]
  value = <<EOF
  nats context save hub --server "%{~ for i, v in module.cluster-hub.private_ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}

output "context_spoke_1" {
  depends_on = [module.cluster-spoke-1]
  value = <<EOF
  nats context save spoke-1 --server "%{~ for i, v in module.cluster-spoke-1.private_ip ~}nats://${v}:4222, %{~ endfor ~}"
EOF
}