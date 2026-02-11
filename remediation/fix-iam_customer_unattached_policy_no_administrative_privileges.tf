# Remove the unattached customer-managed IAM policy that grants administrative privileges
resource "aws_iam_policy" "remediation_aws_cloudtrail_logs_policy" {
  name        = "remediation-aws-cloudtrail-logs-policy"
  description = "Remediation policy to remove administrative privileges"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Action = "*:*",
        Resource = "*"
      }
    ]
  })
}

# Attach the remediation policy to the appropriate IAM users or roles


# Apply permissions boundaries and SCPs as guardrails
resource "aws_organizations_policy" "remediation_scp" {
  name        = "remediation-scp"
  description = "Remediation SCP to enforce least privilege"
  content     = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Action = "*:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "remediation_scp_attachment" {
  policy_id = aws_organizations_policy.remediation_scp.id
  target_id = data.aws_caller_identity.current.account_id
}

# Require peer review and policy validation before attachment
resource "aws_config_configuration_recorder" "remediation_config_recorder" {
  name     = "remediation-config-recorder"
  role_arn = aws_iam_role.remediation_config_recorder_role.arn
}

resource "aws_iam_role" "remediation_config_recorder_role" {
  name = "remediation-config-recorder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}


# Use analysis tools to refine permissions and delete unused policies
data "aws_iam_policy_document" "remediation_refined_policy" {
  statement {
    effect = "Allow"
    actions = [
      "cloudtrail:GetTrailStatus",
      "cloudtrail:StartLogging",
      "cloudtrail:StopLogging"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "remediation_refined_policy" {
  name        = "remediation-refined-policy"
  description = "Refined policy with least privilege"
  policy      = data.aws_iam_policy_document.remediation_refined_policy.json
}