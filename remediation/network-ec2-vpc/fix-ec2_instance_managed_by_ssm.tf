# Enroll the EC2 instance as a Systems Manager managed node
resource "aws_ssm_activation" "remediation_ssm_activation" {
  name               = "remediation-ssm-activation"
  description        = "Activate EC2 instance for Systems Manager"
  iam_role           = "AmazonEC2RoleforSSM"
  registration_limit = 1
  tags = {
    Name = "remediation-ssm-activation"
  }
}

# Attach the Systems Manager managed instance core policy to the instance profile
data "aws_iam_policy" "ssm_managed_instance_core" {
  arn  = var.iam_policy_arn
  name = "AmazonSSMManagedInstanceCore"
}


# Assign the Systems Manager managed instance profile to the EC2 instance
data "aws_iam_instance_profile" "ssm_managed_instance_profile" {
  name = "AmazonEC2RoleforSSM"
}

resource "aws_instance" "remediation_ec2_instance" {
  ami                  = "ami-0b7546e839d7ace12"
  instance_type        = "t2.micro"
  iam_instance_profile = data.aws_iam_instance_profile.ssm_managed_instance_profile.name

  tags = {
    Name = "remediation-ec2-instance"
  }
}

variable "iam_policy_arn" {
  description = "Existing IAM policy ARN"
  type        = string
}
