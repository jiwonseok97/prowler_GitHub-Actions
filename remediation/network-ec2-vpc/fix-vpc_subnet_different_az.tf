variable "vpc_id" {
  type        = string
  description = "VPC ID for the remediation subnets"
  default     = ""
}

variable "subnet_cidr_1" {
  type        = string
  description = "CIDR block for the first remediation subnet"
  default     = ""
}

variable "subnet_cidr_2" {
  type        = string
  description = "CIDR block for the second remediation subnet"
  default     = ""
}

resource "aws_subnet" "remediation_subnet_1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_1
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "remediation_subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_2
  availability_zone = "ap-northeast-2b"
}

data "aws_route_table" "remediation_subnet_1_route_table" {
  subnet_id = aws_subnet.remediation_subnet_1.id
}

data "aws_route_table" "remediation_subnet_2_route_table" {
  subnet_id = aws_subnet.remediation_subnet_2.id
}

resource "aws_vpc_endpoint" "remediation_vpc_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [data.aws_route_table.remediation_subnet_1_route_table.id, data.aws_route_table.remediation_subnet_2_route_table.id]
}
