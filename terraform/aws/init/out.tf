output "public_ip" {
  value = {for i, v in aws_instance.instance: i => v.public_ip}
}

output "private_ip" {
  value = {for i, v in aws_instance.instance: i => v.private_ip}
}

output "x" {
  value = aws_instance.instance
}