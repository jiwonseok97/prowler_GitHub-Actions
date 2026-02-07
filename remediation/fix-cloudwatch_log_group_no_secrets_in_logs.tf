# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Reference the existing CloudWatch log group
data "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name = "/aws/eks/0202_test/cluster"
}

# Apply a data protection policy to the CloudWatch log group
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


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. References the existing CloudWatch log group using the `data` source `aws_cloudwatch_log_group`.
3. Applies a data protection policy to the CloudWatch log group using the `aws_cloudwatch_log_group_policy` resource.
   - The policy allows the `Describe*`, `Get*`, `List*`, `StartQuery`, `StopQuery`, `TestMetricFilter`, and `FilterLogEvents` actions on the log group.
   - The policy denies the `Unmask` action on the log group, which helps prevent the exposure of sensitive data in the logs.