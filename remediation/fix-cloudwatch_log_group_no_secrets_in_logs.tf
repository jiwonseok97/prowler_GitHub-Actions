# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Data source to reference the existing CloudWatch log group
data "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name = "/aws/eks/0202_test/cluster"
}

# Resource to apply a data protection policy to the CloudWatch log group
resource "aws_cloudwatch_log_group_policy" "eks_cluster_log_group_policy" {
  log_group_name = data.aws_cloudwatch_log_group.eks_cluster_log_group.name

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
        "logs:Describe*",
        "logs:Get*",
        "logs:List*",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:TestMetricFilter",
        "logs:FilterLogEvents"
      ],
      "Resource": "${data.aws_cloudwatch_log_group.eks_cluster_log_group.arn}"
    },
    {
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "logs:Unmask"
      ],
      "Resource": "${data.aws_cloudwatch_log_group.eks_cluster_log_group.arn}"
    }
  ]
}
POLICY
}


The Terraform code above does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Uses a data source to reference the existing CloudWatch log group with the name `/aws/eks/0202_test/cluster`.
3. Applies a data protection policy to the CloudWatch log group, which:
   - Allows the `Describe*`, `Get*`, `List*`, `StartQuery`, `StopQuery`, `TestMetricFilter`, and `FilterLogEvents` actions for all principals.
   - Denies the `Unmask` action for all principals, which helps prevent the exposure of sensitive data in the log events.

This code should help address the security finding by applying a data protection policy to the CloudWatch log group and restricting the ability to unmask sensitive data in the log events.