data "aws_iam_role" "github_actions" {
  name = var.role_name
}

# -----------------------------------------------------
# Terraform State Backend Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "terraform_state" {
  name = "TerraformStateAccess"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::${var.state_bucket}/remediation/*"
      },
      {
        Sid    = "S3StateListing"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.state_bucket}"
      },
      {
        Sid    = "DynamoDBLock"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.lock_table}"
      }
    ]
  })
}

# -----------------------------------------------------
# IAM Remediation Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_iam" {
  name = "RemediationIAM"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PasswordPolicy"
        Effect = "Allow"
        Action = [
          "iam:UpdateAccountPasswordPolicy",
          "iam:GetAccountPasswordPolicy",
          "iam:DeleteAccountPasswordPolicy",
        ]
        Resource = "*"
      },
      {
        Sid    = "RoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateRole",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PassRole",
        ]
        Resource = [
          "arn:aws:iam::${var.account_id}:role/remediation_*",
          "arn:aws:iam::${var.account_id}:role/remediation-*",
        ]
      },
      {
        Sid    = "PolicyManagement"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
        ]
        Resource = "arn:aws:iam::${var.account_id}:policy/remediation_*"
      },
      {
        Sid    = "InstanceProfileManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
        ]
        Resource = "arn:aws:iam::${var.account_id}:instance-profile/remediation_*"
      },
      {
        Sid    = "ReadOnly"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListUsers",
          "iam:ListRoles",
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------
# Organizations Remediation Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_organizations" {
  name = "RemediationOrganizations"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OrganizationsManagement"
        Effect = "Allow"
        Action = [
          "organizations:CreateOrganization",
          "organizations:DescribeOrganization",
          "organizations:ListRoots",
          "organizations:EnableAWSServiceAccess",
          "organizations:DisableAWSServiceAccess",
          "organizations:EnablePolicyType",
          "organizations:DisablePolicyType",
          "organizations:CreatePolicy",
          "organizations:UpdatePolicy",
          "organizations:DeletePolicy",
          "organizations:AttachPolicy",
          "organizations:DetachPolicy",
          "organizations:ListPolicies",
          "organizations:DescribePolicy",
          "organizations:ListTargetsForPolicy",
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------
# CloudTrail Remediation Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_cloudtrail" {
  name = "RemediationCloudTrail"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudTrailManagement"
        Effect = "Allow"
        Action = [
          "cloudtrail:CreateTrail",
          "cloudtrail:UpdateTrail",
          "cloudtrail:DeleteTrail",
          "cloudtrail:GetTrail",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:StartLogging",
          "cloudtrail:StopLogging",
          "cloudtrail:AddTags",
          "cloudtrail:RemoveTags",
          "cloudtrail:ListTags",
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------
# CloudWatch Remediation Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_cloudwatch" {
  name = "RemediationCloudWatch"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LogGroups"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:TagLogGroup",
          "logs:UntagLogGroup",
          "logs:ListTagsLogGroup",
          "logs:AssociateKmsKey",
          "logs:DisassociateKmsKey",
          "logs:CreateLogStream",
          "logs:DeleteLogStream",
        ]
        Resource = "*"
      },
      {
        Sid    = "MetricFiltersAndAlarms"
        Effect = "Allow"
        Action = [
          "logs:PutMetricFilter",
          "logs:DeleteMetricFilter",
          "logs:DescribeMetricFilters",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
        ]
        Resource = "*"
      },
      {
        Sid    = "SNS"
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:TagResource",
          "sns:UntagResource",
          "sns:ListTagsForResource",
        ]
        Resource = "arn:aws:sns:${var.aws_region}:${var.account_id}:remediation-*"
      }
    ]
  })
}

# -----------------------------------------------------
# S3 Remediation Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_s3" {
  name = "RemediationS3"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketManagement"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl",
          "s3:GetBucketLogging",
          "s3:PutBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:PutBucketObjectLockConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:PutBucketOwnershipControls",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------
# KMS Remediation Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_kms" {
  name = "RemediationKMS"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KMSManagement"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:EnableKeyRotation",
          "kms:DisableKeyRotation",
          "kms:ScheduleKeyDeletion",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:UpdateAlias",
          "kms:ListAliases",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ListResourceTags",
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------
# EC2/VPC Remediation Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_ec2_vpc" {
  name = "RemediationEC2VPC"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Management"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeImages",
          "ec2:DescribeVolumes",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeNatGateways",
          "ec2:DescribeAddresses",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeFlowLogs",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAvailabilityZones",
        ]
        Resource = "*"
      },
      {
        Sid    = "VPCManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:CreateFlowLogs",
          "ec2:DeleteFlowLogs",
        ]
        Resource = "*"
      },
      {
        Sid    = "SecurityGroupAndACL"
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateNetworkAcl",
          "ec2:DeleteNetworkAcl",
          "ec2:CreateNetworkAclEntry",
          "ec2:DeleteNetworkAclEntry",
          "ec2:ReplaceNetworkAclAssociation",
        ]
        Resource = "*"
      },
      {
        Sid    = "VPCEndpoints"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpcEndpoint",
          "ec2:DeleteVpcEndpoints",
          "ec2:ModifyVpcEndpoint",
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------
# Config Remediation Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_config" {
  name = "RemediationConfig"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConfigManagement"
        Effect = "Allow"
        Action = [
          "config:PutConfigurationRecorder",
          "config:DeleteConfigurationRecorder",
          "config:DescribeConfigurationRecorders",
          "config:DescribeConfigurationRecorderStatus",
          "config:PutDeliveryChannel",
          "config:DeleteDeliveryChannel",
          "config:DescribeDeliveryChannels",
          "config:StartConfigurationRecorder",
          "config:StopConfigurationRecorder",
          "config:PutConfigurationAggregator",
          "config:DeleteConfigurationAggregator",
          "config:DescribeConfigurationAggregators",
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------
# Network Firewall & FMS Permissions
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_firewall" {
  name = "RemediationFirewall"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NetworkFirewall"
        Effect = "Allow"
        Action = [
          "network-firewall:CreateFirewall",
          "network-firewall:DeleteFirewall",
          "network-firewall:DescribeFirewall",
          "network-firewall:UpdateFirewallDeleteProtection",
          "network-firewall:CreateFirewallPolicy",
          "network-firewall:DeleteFirewallPolicy",
          "network-firewall:DescribeFirewallPolicy",
          "network-firewall:CreateRuleGroup",
          "network-firewall:DeleteRuleGroup",
          "network-firewall:DescribeRuleGroup",
          "network-firewall:TagResource",
          "network-firewall:UntagResource",
        ]
        Resource = "*"
      },
      {
        Sid    = "FMS"
        Effect = "Allow"
        Action = [
          "fms:PutPolicy",
          "fms:DeletePolicy",
          "fms:GetPolicy",
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------
# SSM (EC2 instance management)
# -----------------------------------------------------
resource "aws_iam_role_policy" "remediation_ssm" {
  name = "RemediationSSM"
  role = data.aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMAccess"
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstanceInformation",
          "ssm:GetParameter",
          "ssm:PutParameter",
        ]
        Resource = "*"
      }
    ]
  })
}
