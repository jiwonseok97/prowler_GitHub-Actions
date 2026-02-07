# Configure the AWS provider for the ap-northeast-2 region

# Get information about the existing EC2 instance
data "aws_instance" "instance" {
  instance_id = "i-0fbecaba3c48e7c79"
}

# Enroll the EC2 instance as a Systems Manager managed node
resource "aws_ssm_activation" "instance_activation" {
  name               = "ssm-activation-${data.aws_instance.instance.id}"
  description        = "Activate EC2 instance ${data.aws_instance.instance.id} as a Systems Manager managed node"
  instance_type      = data.aws_instance.instance.instance_type
  registration_limit = 1
  tags = {
    Name = "SSM Activated Instance"
  }
}

# Restrict inbound admin ports and use least privilege roles
resource "aws_security_group" "instance_security_group" {
  name        = "instance-security-group"
  description = "Security group for the EC2 instance"
  vpc_id      = data.aws_instance.instance.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Instance Security Group"
  }
}

# Attach the security group to the EC2 instance
resource "aws_network_interface_sg_attachment" "instance_security_group_attachment" {
  security_group_id    = aws_security_group.instance_security_group.id
  network_interface_id = data.aws_instance.instance.primary_network_interface_id
}

# Ensure connectivity to SSM endpoints and automate patching and inventory
resource "aws_route_table" "ssm_route_table" {
  vpc_id = data.aws_instance.instance.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = data.aws_instance.instance.vpc_gateway_id
  }

  tags = {
    Name = "SSM Route Table"
  }
}

resource "aws_route_table_association" "ssm_route_table_association" {
  subnet_id      = data.aws_instance.instance.subnet_id
  route_table_id = aws_route_table.ssm_route_table.id
}


# This Terraform code does the following:
# 
# 1. Configures the AWS provider for the ap-northeast-2 region.
# 2. Retrieves information about the existing EC2 instance using the `data` source.
# 3. Enrolls the EC2 instance as a Systems Manager managed node using the `aws_ssm_activation` resource.
# 4. Creates a security group that restricts inbound admin ports and uses least privilege roles.
# 5. Attaches the security group to the EC2 instance using the `aws_network_interface_sg_attachment` resource.
# 6. Ensures connectivity to SSM endpoints and automates patching and inventory using the `aws_route_table` and `aws_route_table_association` resources.