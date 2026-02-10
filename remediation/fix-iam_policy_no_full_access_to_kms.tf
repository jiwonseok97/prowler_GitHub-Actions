# Modify the existing IAM policy to remove the 'kms:*' privilege and only allow the necessary actions
resource "aws_iam_policy" "remediation_prowler_readonly_policy" {
  name        = "GitHubActionsProwlerRole-ProwlerReadOnly"
  description = "Prowler read-only IAM policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Describe*",
          "kms:Get*",
          "kms:List*",
          "kms:RevokeGrant"
        ],
        Resource = [
          "arn:aws:kms:ap-northeast-2:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "iam:GetAccountPasswordPolicy",
          "iam:GetGroup",
          "iam:GetGroupPolicy",
          "iam:GetInstanceProfile",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetUser",
          "iam:GetUserPolicy",
          "iam:ListAccessKeys",
          "iam:ListAttachedGroupPolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
          "iam:ListGroups",
          "iam:ListGroupsForUser",
          "iam:ListInstanceProfiles",
          "iam:ListInstanceProfilesForRole",
          "iam:ListMFADevices",
          "iam:ListPolicies",
          "iam:ListPolicyVersions",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListUsers",
          "iam:ListUserPolicies",
          "kms:Describe*",
          "kms:Get*",
          "kms:List*",
          "kms:RevokeGrant",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",
          "logs:GetLogEvents",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketVersioning",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "ssm:DescribeAssociation",
          "ssm:DescribeInstanceInformation",
          "ssm:GetDocument",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:ListDocuments"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the modified IAM policy to the existing IAM role
resource "aws_iam_role_policy_attachment" "remediation_prowler_readonly_policy_attachment" {
  policy_arn = aws_iam_policy.remediation_prowler_readonly_policy.arn
  role       = "GitHubActionsProwlerRole"
}