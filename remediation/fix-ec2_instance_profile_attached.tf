# Attach an IAM instance profile to the EC2 instance
data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
}

# Create an IAM role with the required permissions
data "aws_iam_role" "remediation_role" {
  name = "remediation-role"
}

# Associate the IAM instance profile with the EC2 instance
resource "aws_instance" "remediation_instance" {
  ami = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = data.aws_iam_instance_profile.remediation_instance_profile.name
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