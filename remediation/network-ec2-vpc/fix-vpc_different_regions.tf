variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  type        = number
  description = "Number of subnets to create in the VPC"
  default     = 2
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "remediation_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "Remediation VPC"
  }
}

resource "aws_subnet" "remediation_subnets" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.remediation_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "Remediation Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "remediation_igw" {
  vpc_id = aws_vpc.remediation_vpc.id
  tags = {
    Name = "Remediation Internet Gateway"
  }
}

resource "aws_route_table" "remediation_rt" {
  vpc_id = aws_vpc.remediation_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.remediation_igw.id
  }
  tags = {
    Name = "Remediation Route Table"
  }
}

resource "aws_route_table_association" "remediation_rt_association" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.remediation_subnets[count.index].id
  route_table_id = aws_route_table.remediation_rt.id
}

resource "aws_security_group" "remediation_sg" {
  name   = "Remediation-Security-Group"
  vpc_id = aws_vpc.remediation_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
