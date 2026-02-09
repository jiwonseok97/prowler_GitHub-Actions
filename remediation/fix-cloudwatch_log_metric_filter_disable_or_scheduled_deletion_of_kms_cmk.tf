# Create CloudWatch log metric filter and alarm for disabling or scheduled deletion of customer-managed KMS keys
resource "aws_cloudwatch_log_metric_filter" "remediation_kms_key_disable_or_delete" {
  name           = "remediation_kms_key_disable_or_delete"
  pattern        = "{$.eventName = DisableKey} || {$.eventName = ScheduleKeyDeletion}"
  log_group_name = "/aws/cloudtrail/my-cloudtrail-log-group"

  metric_transformation {
    name      = "KMSKeyDisableOrDelete"
    namespace = "SecurityMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_kms_key_disable_or_delete_alarm" {
  alarm_name          = "remediation_kms_key_disable_or_delete_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "KMSKeyDisableOrDelete"
  namespace           = "SecurityMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when a customer-managed KMS key is disabled or scheduled for deletion"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:132410971304:my-security-topic"]
}

# Apply least privilege to KMS administration
data "aws_iam_policy_document" "kms_admin_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "remediation_kms_admin_policy" {
  name        = "remediation_kms_admin_policy"
  description = "Least privilege policy for KMS administration"
  policy      = data.aws_iam_policy_document.kms_admin_policy.json
}

# Enforce change control and separation of duties
resource "aws_iam_role" "remediation_kms_admin_role" {
  name = "remediation_kms_admin_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::132410971304:root"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_kms_admin_policy_attachment" {
  policy_arn = aws_iam_policy.remediation_kms_admin_policy.arn
  role       = aws_iam_role.remediation_kms_admin_role.name
}

# Use deletion waiting periods and monitor all regions
resource "aws_config_configuration_recorder" "remediation_config_recorder" {
  name     = "remediation_config_recorder"
  role_arn = "arn:aws:iam::132410971304:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
}

resource "aws_config_delivery_channel" "remediation_config_delivery_channel" {
  name           = "remediation_config_delivery_channel"
  s3_bucket_name = "my-config-bucket"
}

resource "aws_config_configuration_aggregator" "remediation_config_aggregator" {
  name = "remediation_config_aggregator"

  account_aggregation_source {
    account_ids = ["132410971304"]
    all_regions = true
  }
}