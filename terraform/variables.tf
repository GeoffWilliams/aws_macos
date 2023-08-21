variable "aws_region" {
  description = "aws region to use (global to script)"
}
variable "owner_name" {
  description = "used for the owner_name tag"
}
variable "owner_email" {
  description = "used for the owner_email tag"
}
variable "lab_name" {
  description = "AWS console name for VPC and associated items"
}
variable "public_access_cidr" {
  description = "CIDR to allow access from/IP+netmask address of your home router for SSH access (ex [X.X.X.X/32])"
}
variable "ec2_key_name" {
  description = "Name of your EC2 keypair for SSH access"
}
variable "ec2_instance_type" {
  description = "AWS instance type to use for k3s"
}
variable "ec2_volume_size" {
  description = "Size of EBS volume (GB)"
}