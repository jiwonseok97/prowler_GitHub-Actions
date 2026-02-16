data "aws_iam_instance_profile" "remediation_instance_profile" {
  name = var.iam_instance_profile_name
}

resource "aws_instance" "remediation_i_0fbecaba3c48e7c79" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = data.aws_iam_instance_profile.remediation_instance_profile.name
}

resource "aws_cloudwatch_log_group" "remediation_log_group" {
  name = "remediation-log-group-var.iam_role_name"
}

resource "aws_cloudwatch_log_stream" "remediation_log_stream" {
  name           = "remediation-log-stream-var.iam_role_name"
  log_group_name = aws_cloudwatch_log_group.remediation_log_group.name
}

resource "aws_cloudwatch_metric_alarm" "remediation_role_usage_alarm" {
  alarm_name          = "remediation-role-usage-alarm-${var.iam_role_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RoleUsage"
  namespace           = "AWS/IAM"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm when the remediation role is used"
  alarm_actions       = [var.sns_topic_arn]
}

variable "ami_id" {
  description = "AMI ID for new or managed instances"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Existing IAM instance profile name"
  type        = string
}

variable "iam_role_name" {
  description = "Existing IAM role name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN"
  type        = string
}
