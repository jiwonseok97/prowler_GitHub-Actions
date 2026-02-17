# Attach an IAM instance profile to the EC2 instance
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

resource "aws_instance" "remediation_ec2_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  iam_instance_profile = var.iam_instance_profile_name

  vpc_security_group_ids = tolist(data.aws_security_groups.default.ids)
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]

  tags = {
    Name = "Remediated EC2 Instance"
  }
}

# Use existing IAM role and policy
data "aws_iam_role" "existing_role" {
  name = var.iam_role_name
}

data "aws_iam_policy" "existing_policy" {
  arn = var.iam_policy_arn
}

# Attach the existing IAM policy to the existing IAM role

# Use existing AMI and security groups

data "aws_security_groups" "default" {
  tags = {
    Name = "default"
  }
}

data "aws_subnets" "default" {
  filter {
    name = "default-for-az"
    values = ["true"]
  }
}

# Use input variables for IAM role, policy, and instance profile names
variable "iam_role_name" {
  type        = string
  description = "Name of the existing IAM role to use"
  default     = ""
}

variable "iam_policy_arn" {
  type        = string
  description = "ARN of the existing IAM policy to attach"
  default     = ""
}

variable "iam_instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile to create"
  default     = ""
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}
