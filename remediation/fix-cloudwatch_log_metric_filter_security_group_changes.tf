# Get the existing CloudWatch Logs log group name
data "aws_cloudwatch_log_group" "existing_log_group" {
  name = "arn:aws:logs:ap-northeast-2:132410971304:log-group"
}

# Create a CloudWatch Logs metric filter to capture security group changes
resource "aws_cloudwatch_log_metric_filter" "remediation_security_group_changes" {
  name           = "remediation-security-group-changes"
  pattern        = "{$.eventName = AuthorizeSecurityGroupIngress} || {$.eventName = AuthorizeSecurityGroupEgress} || {$.eventName = RevokeSecurityGroupIngress} || {$.eventName = RevokeSecurityGroupEgress} || {$.eventName = CreateSecurityGroup} || {$.eventName = DeleteSecurityGroup}"
  log_group_name = data.aws_cloudwatch_log_group.existing_log_group.name

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "MyApp/SecurityChanges"
    value     = "1"
  }
}

# Create a CloudWatch alarm to trigger on security group changes
resource "aws_cloudwatch_metric_alarm" "remediation_security_group_changes_alarm" {
  alarm_name          = "remediation-security-group-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityGroupChanges"
  namespace           = "MyApp/SecurityChanges"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when security group changes are detected"
  alarm_actions       = [aws_sns_topic.remediation_security_alerts.arn]
}

# Create an SNS topic to receive security group change alerts
resource "aws_sns_topic" "remediation_security_alerts" {
  name = "remediation-security-alerts"
}

# Create an IAM policy to restrict security group changes
resource "aws_iam_policy" "remediation_restrict_security_group_changes" {
  name        = "remediation-restrict-security-group-changes"
  description = "Restrict security group changes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny",
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup"
        ],
        Resource = "*",
        Condition = {
          StringNotEquals = {
            "aws:PrincipalTag/Environment" = "production"
          }
        }
      }
    ]
  })
}