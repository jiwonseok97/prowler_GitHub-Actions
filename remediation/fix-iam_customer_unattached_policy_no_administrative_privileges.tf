# Remove the unattached customer-managed IAM policy
resource "aws_iam_policy" "remediation_aws_cloudtrail_logs_policy" {
  name        = "remediation-aws-cloudtrail-logs-policy"
  description = "Remediation policy for AWS CloudTrail logs"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:StartLogging",
          "cloudtrail:StopLogging"
        ],
        Resource = "*"
      }
    ]
  })
}

# Apply a permissions boundary to the IAM policy
resource "aws_iam_policy" "remediation_permissions_boundary" {
  name        = "remediation-permissions-boundary"
  description = "Permissions boundary for remediation resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        NotAction = "*:*",
        Resource = "*"
      }
    ]
  })
}

# Attach the permissions boundary to the IAM policy

# Create an IAM role for the remediation resources
resource "aws_iam_role" "remediation_role" {
  name               = "remediation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the remediation policy to the IAM role

# Create an EC2 instance with the remediation role
resource "aws_instance" "remediation_instance" {
  ami           = "ami-0b7546e839d7ace12"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.remediation_instance_profile.name
}

# Create an IAM instance profile for the remediation instance
resource "aws_iam_instance_profile" "remediation_instance_profile" {
  name = "remediation-instance-profile"
  role = aws_iam_role.remediation_role.name
}