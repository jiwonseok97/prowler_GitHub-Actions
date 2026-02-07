# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the existing CloudWatch log group
data "aws_cloudwatch_log_group" "eks_log_group" {
  name = "/aws/eks/0202_test/cluster"
}

# Apply a data protection policy to the CloudWatch log group
resource "aws_cloudwatch_log_group_policy" "eks_log_group_policy" {
  log_group_name = data.aws_cloudwatch_log_group.eks_log_group.name

  policy_document = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogStream"
      ],
      "Resource": "${data.aws_cloudwatch_log_group.eks_log_group.arn}"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "logs:Unmask"
      ],
      "Resource": "${data.aws_cloudwatch_log_group.eks_log_group.arn}",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "o-1234567890"
        }
      }
    }
  ]
}
POLICY
}

# Reduce the retention period for the CloudWatch log group to 30 days
resource "aws_cloudwatch_log_group" "eks_log_group" {
  name              = data.aws_cloudwatch_log_group.eks_log_group.name
  retention_in_days = 30
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Retrieves the existing CloudWatch log group using the `data` source `aws_cloudwatch_log_group`.
3. Applies a data protection policy to the CloudWatch log group using the `aws_cloudwatch_log_group_policy` resource. This policy allows the necessary actions for log events and restricts the `logs:Unmask` action to a specific AWS organization.
4. Reduces the retention period for the CloudWatch log group to 30 days using the `aws_cloudwatch_log_group` resource.