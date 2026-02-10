# Create a CloudWatch log metric filter to detect DisableKey and ScheduleKeyDeletion events
resource "aws_cloudwatch_log_metric_filter" "remediation_kms_key_disable_or_delete" {
  name           = "remediation-kms-key-disable-or-delete"
  pattern        = <<-EOT
    { ($.eventName = DisableKey) || ($.eventName = ScheduleKeyDeletion) }
  EOT
  log_group_name = "my-kms-key-activity-log-group"

  metric_transformation {
    name      = "KMSKeyDisableOrDelete"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on the KMS key disable/delete metric
resource "aws_cloudwatch_metric_alarm" "remediation_kms_key_disable_or_delete_alarm" {
  alarm_name          = "remediation-kms-key-disable-or-delete-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "KMSKeyDisableOrDelete"
  namespace           = "SecurityMetrics"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when a customer-managed KMS key is disabled or scheduled for deletion"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-notifications"]
}

# Apply least privilege to KMS administration
data "aws_iam_policy_document" "remediation_kms_admin_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "remediation_kms_admin_policy" {
  name        = "remediation-kms-admin-policy"
  description = "Least privilege policy for KMS key administration"
  policy      = jsonencode(data.aws_iam_policy_document.remediation_kms_admin_policy.json)
}

# Enforce change control and separation of duties
resource "aws_iam_user_policy_attachment" "remediation_kms_admin_policy_attachment" {
  policy_arn = aws_iam_policy.remediation_kms_admin_policy.arn
  user       = "kms-admin-user"
}

# Use deletion waiting periods and monitor all regions
resource "aws_kms_key" "remediation_customer_managed_kms_key" {
  description             = "Customer-managed KMS key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}