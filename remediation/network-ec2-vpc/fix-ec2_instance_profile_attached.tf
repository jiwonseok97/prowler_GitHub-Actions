# Attach an IAM instance profile to the EC2 instance
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

resource "aws_instance" "remediation_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  iam_instance_profile = var.iam_instance_profile_name

  vpc_security_group_ids = [
    var.security_group_id
  ]

  tags = {
    Name = "Remediated Instance"
  }
}

# Use variables for IAM role and policy references
variable "iam_role_name" {
  default = "remediation-role"
}

variable "iam_policy_arn" {
  default = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the required IAM policy to the role

# Use data sources to look up existing resources

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
  default     = ""
}

variable "security_group_id" {
  description = "Target security group ID"
  type        = string
  default     = ""
}

variable "iam_instance_profile_name" {
  description = "Existing IAM instance profile name"
  type        = string
}
