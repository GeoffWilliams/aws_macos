provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "owner_name"  = var.owner_name
      "owner_email" = var.owner_email
    }
  }
}

# Lookup the current AMI for macOS 13.5 (Ventura)
data "aws_ami" "macos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ec2-macos-13.5-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["839598134531"] # Apple
}

# availablility zone names
data "aws_availability_zones" "available" {
  state = "available"
}

# # vpc
# resource "aws_vpc" "vpc" {
#   cidr_block           = "172.16.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#   tags                 = {
#     Name = var.lab_name
#   }
# }


# # igw
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.vpc.id
#   tags   = {
#     Name = var.lab_name
#   }
# }

# ssh in
resource "aws_security_group" "public_access" {
  name        = "${var.lab_name}-macos-external-access"
  description = "External access for ${var.lab_name}"
  # vpc_id      = aws_vpc.vpc.id
  tags        = {
    Name = "${var.lab_name}-external-access"
  }

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "ssh"
    cidr_blocks = var.public_access_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# subnet
# resource "aws_subnet" "public" {
#   cidr_block              = "172.16.0.0/24"
#   vpc_id                  = aws_vpc.vpc.id
#   map_public_ip_on_launch = true
#   tags                    = {
#     Name = "${var.lab_name} - public"
#   }
# }

resource "aws_network_interface_sg_attachment" "instance_attachment" {
  security_group_id    = aws_security_group.public_access.id
  network_interface_id = aws_instance.macos.primary_network_interface_id
}

# dedicated host
# macOS requires a dedicated host that EC2 instances will be created on
resource "aws_ec2_host" "mac" {
  instance_type     = var.ec2_instance_type
  availability_zone =  data.aws_availability_zones.available.names[0]
  auto_placement    = "on"
}

# ec2 instance
resource "aws_instance" "macos" {
  ami                         = data.aws_ami.macos.id
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
#  vpc_security_group_ids      = [aws_security_group.public_access.id]
#  subnet_id                   = aws_subnet.public.id
  # Dedicated tenancy settings
  tenancy                     = "host"
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.ec2_volume_size
    delete_on_termination = true
  }
  tags = {
    Name = "${var.owner_name} - macOS"
    hostname = "macOS"
  }
  # metadata_options {
  #   http_endpoint          = "enabled"
  #   instance_metadata_tags = "enabled"
  # }
  lifecycle {
    ignore_changes = [ami]
  }
}

output "sshconfig" {
  value = <<-EOF
    Host macos
      HostName ${aws_instance.macos.public_dns}
      User ec2-user
      IdentityFile=~/.ssh/aws.pem
  EOF
}


