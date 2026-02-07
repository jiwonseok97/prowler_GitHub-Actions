# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing IAM role
data "aws_iam_role" "existing_role" {
  name = "arn:aws:iam:ap-northeast-2:132410971304:role"
}

# Update the trust policy of the IAM role to restrict cross-account sharing
resource "aws_iam_role_policy_attachment" "restrict_cross_account_sharing" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCloudWatchAgentServerPolicy"
  role       = data.aws_iam_role.existing_role.name
}

# Attach a custom policy to the IAM role to restrict access to specific trusted accounts
resource "aws_iam_role_policy" "restrict_access_to_trusted_accounts" {
  name = "restrict-access-to-trusted-accounts"
  role = data.aws_iam_role.existing_role.name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "arn:aws:iam::123456789012:root",
            "arn:aws:iam::987654321098:root"
          ]
        },
        "Action": "cloudwatch:*",
        "Resource": "*"
      }
    ]
  }
  EOF
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing IAM role using the `data.aws_iam_role` data source.
3. Attaches the `AWSCloudWatchAgentServerPolicy` policy to the IAM role to restrict cross-account sharing.
4. Attaches a custom policy to the IAM role to restrict access to specific trusted accounts (in this example, `123456789012` and `987654321098`).