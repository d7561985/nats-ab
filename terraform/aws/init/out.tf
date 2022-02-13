output "public_ip" {
  value = {for i, v in aws_instance.instance: i => v.public_ip}
}
