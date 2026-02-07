# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing IAM user
data "aws_iam_user" "github_actions_prowler" {
  user_name = "github-actions-prowler"
}

# Create a new IAM policy with least-privilege permissions for KMS
resource "aws_iam_policy" "kms_least_privilege" {
  name        = "kms-least-privilege"
  description = "Least-privilege permissions for KMS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": [
        "arn:aws:kms:ap-northeast-2:132410971304:key/*"
      ]
    }
  ]
}
EOF
}

# Attach the new IAM policy to the existing IAM user
resource "aws_iam_user_policy_attachment" "github_actions_prowler_kms_least_privilege" {
  user       = data.aws_iam_user.github_actions_prowler.user_name
  policy_arn = aws_iam_policy.kms_least_privilege.arn
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing IAM user `github-actions-prowler` using a data source.
3. Creates a new IAM policy named `kms-least-privilege` with the recommended least-privilege permissions for KMS, including `kms:Encrypt`, `kms:Decrypt`, `kms:ReEncrypt*`, `kms:GenerateDataKey*`, and `kms:DescribeKey` actions, limited to the specific KMS key ARN.
4. Attaches the new IAM policy to the existing IAM user `github-actions-prowler`.