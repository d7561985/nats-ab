output "public_ip" {
  value = module.cluster-hub.public_ip
}

output "spoke-1-public_ip" {
  value = module.cluster-spoke-1.public_ip
}