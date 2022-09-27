output "public_ip" {
  depends_on = [module.cluster-hub]
  value = module.cluster-hub.public_ip
}

output "spoke-1-public_ip" {
  depends_on = [module.cluster-spoke-1]

  value = module.cluster-spoke-1.public_ip
}

output "spoke-2-public_ip" {
  depends_on = [module.cluster-spoke-2]

  value = module.cluster-spoke-2.public_ip
}

output "private_context_sys" {
  value = {
    upload-hub: module.upload-hub.private_context_sys,
    upload-leaf : module.upload-leaf.private_context_sys,
    upload-leaf2: module.upload-leaf2.private_context_sys,
  }
}

output "private_context_acc" {
  value = {
    upload-hub: module.upload-hub.private_context_acc,
    upload-leaf : module.upload-leaf.private_context_acc,
    upload-leaf2: module.upload-leaf2.private_context_acc,
  }
}

output "public_context_sys" {
  value = {
    upload-hub: module.upload-hub.public_context_sys,
    upload-leaf : module.upload-leaf.public_context_sys,
    upload-leaf2: module.upload-leaf2.public_context_sys,
  }
}

output "public_context_acc" {
  value = {
    upload-hub: module.upload-hub.public_context_acc,
    upload-leaf : module.upload-leaf.public_context_acc,
    upload-leaf2: module.upload-leaf2.public_context_acc,
  }
}