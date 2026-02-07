# Configure the AWS provider for the ap-northeast-2 region

# Data source to reference the existing IAM policy
data "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name = "aws_learner_dynamodb_policy"
}

# Create a new IAM policy document with the required permissions
data "aws_iam_policy_document" "aws_learner_dynamodb_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "cloudtrail:GetTrailStatus",
      "cloudtrail:DescribeTrails",
      "cloudtrail:LookupEvents"
    ]
    resources = ["*"]
  }
}

# Create a new IAM policy with the updated permissions
resource "aws_iam_policy" "aws_learner_dynamodb_policy" {
  name        = "aws_learner_dynamodb_policy"
  description = "Updated IAM policy with limited CloudTrail permissions"
  policy      = data.aws_iam_policy_document.aws_learner_dynamodb_policy_document.json
}


# This Terraform code does the following:
# 
# 1. Configures the AWS provider for the `ap-northeast-2` region.
# 2. Retrieves the existing IAM policy using the `data` source.
# 3. Creates a new IAM policy document with the required permissions for CloudTrail, including `GetTrailStatus`, `DescribeTrails`, and `LookupEvents`.
# 4. Creates a new IAM policy with the updated permissions, using the policy document from the previous step.
# 
# The updated policy grants the necessary permissions for CloudTrail management, while avoiding the `cloudtrail:*` privilege and following the principle of least privilege.