# Remove the AWSCloudShellFullAccess policy attachment from all IAM identities
resource "aws_iam_user_policy_attachment" "remediation_remove_cloudshell_admin_from_users" {
  for_each = toset([
    "example_user1",
    "example_user2",
    # Add any other IAM user names that have the AWSCloudShellFullAccess policy attached
  ])
  user       = each.key
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
}

resource "aws_iam_group_policy_attachment" "remediation_remove_cloudshell_admin_from_groups" {
  for_each = toset([
    "example_group1",
    "example_group2",
    # Add any other IAM group names that have the AWSCloudShellFullAccess policy attached
  ])
  group      = each.key
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
}

resource "aws_iam_role_policy_attachment" "remediation_remove_cloudshell_admin_from_roles" {
  for_each = toset([
    "example_role1",
    "example_role2",
    # Add any other IAM role names that have the AWSCloudShellFullAccess policy attached
  ])
  role       = each.key
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
}

# Alternatively, you can create a new IAM role with the required permissions for CloudShell access
# and assign it to the necessary EC2 instances or other resources that need CloudShell access.
# This approach allows you to apply the principle of least privilege.

# Example of creating a new IAM role for CloudShell access
resource "aws_iam_role" "remediation_cloudshell_access_role" {
  name = "remediation-cloudshell-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_cloudshell_access_role_policy" {
  role       = aws_iam_role.remediation_cloudshell_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
}

# Example of assigning the new IAM role to an EC2 instance
resource "aws_instance" "remediation_ec2_with_cloudshell_access" {
  ami           = "ami-0b0af3577fe5e3532" # Replace with the desired AMI
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.remediation_cloudshell_access_profile.name
}

resource "aws_iam_instance_profile" "remediation_cloudshell_access_profile" {
  name = "remediation-cloudshell-access-profile"
  role = aws_iam_role.remediation_cloudshell_access_role.name
}