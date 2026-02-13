# Retrieve the existing EC2 instance details
data "aws_instance" "remediation_instance" {
}

# Create a new subnet in the same VPC as the existing instance
resource "aws_subnet" "remediation_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.2.0/24"
}

# Create a new network interface in the new subnet
resource "aws_network_interface" "remediation_network_interface" {
  subnet_id = aws_subnet.remediation_subnet.id
  security_groups = tolist(data.aws_instance.remediation_instance.vpc_security_group_ids)
}

# Attach the new network interface to the existing EC2 instance
resource "aws_network_interface_attachment" "remediation_attachment" {
  instance_id = var.instance_id
  network_interface_id = aws_network_interface.remediation_network_interface.id
  device_index         = 1
}

# Update the EC2 instance to use the new network interface
resource "aws_instance" "remediation_instance" {
  ami = var.ami_id
  instance_type = var.instance_type
  network_interface {
    network_interface_id = aws_network_interface.remediation_network_interface.id
    device_index         = 0
  }
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}

variable "instance_id" {
  description = "instance_id"
  type        = string
  default     = ""
}