variable "ENVIRONMENT" {
  type    = string
  default = "nats-test"
}

variable "AWS_REGION" {
  type    = string
  default = "eu-central-1"
}
#
#variable "IMAGE" {
#  type    = string
#  # aws ec2 describe-images --filters "Name=root-device-type,Values=ebs" "Name=name,Values=amzn2-ami-kernel-5.10-hvm-2.0.20211201.0-x86_64-gp2" --region eu-central-1
#  default = "ami-05d34d340fb1d89e5"
#}

variable "CERT_KEY" {
  type    = string
  default = "id_rsa"
}

variable "SPOT_PRICE" {
  default = "0.1"
}

variable "names" {
  type    = set(string)
  default = ["rs1", "rs2", "rs3"]
}

variable "INSTANCE_TYPE" {
  type = string
  default = "t3.medium"
}

variable "ports" {
  type = set(string)
  default = [22]
}
