provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter to detect security group changes
resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "security-group-changes"
  pattern        = "{$.eventName = AuthorizeSecurityGroupIngress} || {$.eventName = AuthorizeSecurityGroupEgress} || {$.eventName = RevokeSecurityGroupIngress} || {$.eventName = RevokeSecurityGroupEgress} || {$.eventName = CreateSecurityGroup} || {$.eventName = DeleteSecurityGroup}"
  log_group_name = data.aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "SecurityAudit"
    value     = "1"