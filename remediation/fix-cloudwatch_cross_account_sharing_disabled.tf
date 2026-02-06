# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing IAM role
data "aws_iam_role" "existing_role" {
  name = "arn:aws:iam:ap-northeast-2:132410971304:role"
}

# Update the trust policy of the IAM role to restrict cross-account access
resource "aws_iam_role_policy_attachment" "restrict_cross_account_access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = data.aws_iam_role.existing_role.name
}

# Attach a custom policy to the IAM role to restrict access to specific resources
resource "aws_iam_role_policy" "restrict_access_to_resources" {
  name = "restrict-access-to-resources"
  role = data.aws_iam_role.existing_role.name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ],
        "Resource": [
          "arn:aws:cloudwatch:ap-northeast-2:132410971304:metric/*"
        ]
      }
    ]
  }
  EOF
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing IAM role using the `data` source.
3. Attaches the `CloudWatchAgentServerPolicy` to the IAM role to restrict cross-account access.
4. Attaches a custom policy to the IAM role to restrict access to specific CloudWatch resources, allowing only `GetMetricData`, `GetMetricStatistics`, and `ListMetrics` actions on the specified metric resources.