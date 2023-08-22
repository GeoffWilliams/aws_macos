provider "aws" {
  region = var.aws_region
  # eg...
  profile = var.aws_profile
  default_tags {
    tags = {
      "owner_name"  = var.owner_name
      "owner_email" = var.owner_email
    }
  }
}

# Lookup the current AMI for macOS 13.5 (Ventura)
# To find the deets of an image use the API or click the "community" tab in AMI Catalog, then find the image and
# lookup the details
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

  # Amazon (Apple) - different in every region
  owners = ["605624831197"]
}

# availablility zone names
data "aws_availability_zones" "available" {
  state = "available"
}

# upload our "normal" SSH key
resource "aws_key_pair" "keypair" {
  key_name   = "gwilliams-${var.lab_name}"
  public_key = file("~/.ssh/id_rsa.pub")
}


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
  tags = {
    Name = "${var.owner_name} - macOS"
  }
}

# ec2 instance
resource "aws_instance" "macos" {
  ami                         = data.aws_ami.macos.id
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.keypair.key_name
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
  lifecycle {
    ignore_changes = [ami]
  }
}

output "sshconfig" {
  value = <<-EOF
    Host macos
      HostName ${aws_instance.macos.public_dns}
      User ec2-user
      IdentityFile=~/.ssh/id_rsa
  EOF
}


