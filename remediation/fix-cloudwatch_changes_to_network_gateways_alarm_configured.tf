# Create a CloudWatch log group to receive CloudTrail logs
resource "aws_cloudwatch_log_group" "remediation_cloudtrail_log_group" {
  name = "remediation-cloudtrail-logs"
}

# Create a CloudTrail trail to send logs to the CloudWatch log group
resource "aws_cloudtrail" "remediation_cloudtrail" {
  name                          = "remediation-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.remediation_cloudtrail_bucket.id
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.remediation_cloudtrail_log_group.arn
  cloud_watch_logs_role_arn      = aws_iam_role.remediation_cloudtrail_role.arn
}

# Create an S3 bucket to store CloudTrail logs
resource "aws_s3_bucket" "remediation_cloudtrail_bucket" {
  bucket = "remediation-cloudtrail-bucket"

}

# Create an IAM role for CloudTrail to write logs to CloudWatch
resource "aws_iam_role" "remediation_cloudtrail_role" {
  name = "remediation-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the CloudWatchLogsFullAccess policy to the CloudTrail role
resource "aws_iam_role_policy_attachment" "remediation_cloudtrail_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = aws_iam_role.remediation_cloudtrail_role.name
}

# Create a CloudWatch metric filter for network gateway changes
resource "aws_cloudwatch_log_metric_filter" "remediation_network_gateway_changes_filter" {
  name           = "remediation-network-gateway-changes"
  pattern        = "{$.eventName = CreateCustomerGateway} || {$.eventName = DeleteCustomerGateway} || {$.eventName = AttachInternetGateway} || {$.eventName = DetachInternetGateway} || {$.eventName = CreateVpnConnection} || {$.eventName = DeleteVpnConnection} || {$.eventName = CreateVpnGateway} || {$.eventName = DeleteVpnGateway} || {$.eventName = EnableVgwRoutePropagation} || {$.eventName = DisableVgwRoutePropagation}"
  log_group_name = aws_cloudwatch_log_group.remediation_cloudtrail_log_group.name

  metric_transformation {
    name      = "NetworkGatewayChanges"
    namespace = "MyApp/SecurityLogs"
    value     = "1"
  }
}

# Create a CloudWatch alarm for network gateway changes
resource "aws_cloudwatch_metric_alarm" "remediation_network_gateway_changes_alarm" {
  alarm_name          = "remediation-network-gateway-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.remediation_network_gateway_changes_filter.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.remediation_network_gateway_changes_filter.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when network gateway changes occur"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:${data.aws_caller_identity.current.account_id}:my-security-topic"]
}

# Get the current AWS account ID