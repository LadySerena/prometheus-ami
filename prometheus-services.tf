provider "aws" {
  profile = "default"
  region     = "us-east-2"
}
data "aws_iam_policy_document" "minecraft_read_only" {
  statement {
    sid = "1"
    effect = "Allow"
    actions = [
      "ec2:Describe*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "2"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:Describe*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "3"
    effect = "Allow"
    actions = [
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:Describe*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "4"
    effect = "Allow"
    actions = [
      "autoscaling:Describe*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "6"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "${aws_iam_role.prometheus_role.arn}"
    ]
  }

}

data "aws_iam_policy_document" "minecraft_assume_role" {
  statement {
    sid = "5"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}


resource "aws_iam_role_policy" "prometheus_ec2_read_only" {
  name = "prometheus_ec2_read_only"
  role = aws_iam_role.prometheus_role.id
  policy = data.aws_iam_policy_document.minecraft_read_only.json
}

resource "aws_iam_instance_profile" "prometheus_profile" {
  name = "prometheus_profile"
  role = aws_iam_role.prometheus_role.name
}

resource "aws_iam_role" "prometheus_role" {
  name = "prometheus_role"
  description = "role to allow prometheus to use the ec2 service discovery"
  tags = {
    createdViaTerraform = "true"
  }
  assume_role_policy = data.aws_iam_policy_document.minecraft_assume_role.json
}

resource "aws_vpc" "terraform" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "terraform"
  }
}

resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = aws_vpc.terraform.id

  tags = {
    Name = "terraform_gw"
  }
}

resource "aws_route" "r" {
  route_table_id            = aws_vpc.terraform.main_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.terraform_gw.id
  depends_on                = [aws_vpc.terraform]
}




resource "aws_subnet" "terraform_subnet_0" {
  vpc_id     = aws_vpc.terraform.id
  cidr_block = "192.168.32.0/20"
  tags = {
    Name = "terraform_subnet_0"
  }
}


resource "aws_instance" "prometheus" {
  depends_on = [aws_internet_gateway.terraform_gw]
  ami = "ami-061e83a8fc9897918"
  instance_type = "t2.micro"
  key_name = "serena-test"
  iam_instance_profile = "prometheus_profile"
  instance_initiated_shutdown_behavior = "terminate"
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.prometheus_security_group.id
  ]
  root_block_device {
    delete_on_termination = true
  }
  subnet_id = aws_subnet.terraform_subnet_0.id
  tags = {
    Name = "prometheus"
  }
}

resource "aws_security_group" "prometheus_security_group" {
  name = "allow http"
  description = "allow inbound http traffic"
  vpc_id = aws_vpc.terraform.id

  ingress {
    from_port = 9090
    to_port = 9090
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

