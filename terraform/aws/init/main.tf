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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  availability_zone = "${var.AWS_REGION}a"
  vpc_id            = data.aws_vpc.default.id
}

data "aws_subnet" "b" {
  availability_zone = "${var.AWS_REGION}b"
  vpc_id            = data.aws_vpc.default.id
}

resource "aws_security_group" "instance" {
  name        = var.ENVIRONMENT
  description = "Security group for ${var.ENVIRONMENT}"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = var.ENVIRONMENT
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.instance.id
}

resource "aws_security_group_rule" "ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.instance.id
}

resource "aws_security_group_rule" "nats" {
  for_each    = var.ports
  type        = "ingress"
  from_port   = each.value
  to_port     = each.value
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0", data.aws_vpc.default.cidr_block]

  security_group_id = aws_security_group.instance.id
}

resource "aws_launch_template" "template" {
  name          = var.ENVIRONMENT
  key_name      = var.CERT_KEY
  instance_type = "t3.medium"
  image_id      = data.aws_ami.ami.id
  ebs_optimized = false

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.SPOT_PRICE
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.ENVIRONMENT
    }
  }

  user_data = filebase64("${path.module}/userdata.sh")
}

resource "aws_instance" "instance" {
  for_each = var.names

  instance_type = var.INSTANCE_TYPE

  #  availability_zone = "${var.AWS_REGION}a"
  subnet_id       = data.aws_subnet.default.id
  security_groups = [aws_security_group.instance.id]

  launch_template {
    id      = aws_launch_template.template.id
    version = aws_launch_template.template.latest_version
  }

  depends_on = [aws_launch_template.template]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    #    iops        = 16000
    #    throughput  = 250
  }

  user_data_base64 = filebase64("${path.module}/userdata.sh")
  tags = {
    Name = each.value
  }
}