provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter to capture NACL change events from CloudTrail
resource "aws_cloudwatch_log_metric_filter" "nacl_changes" {
  name           = "nacl-changes"
  pattern        = "{$.eventName = CreateNetworkAcl} || {$.eventName = CreateNetworkAclEntry} || {$.eventName = DeleteNetworkAcl} || {$.eventName = DeleteNetworkAclEntry} || {$.eventName = ReplaceNetworkAclEntry} || {$.eventName = ReplaceNetworkAcl}"
  log_group_name = "data.aws_cloudwatch_log_group.cloudtrail_log_group.name"

  metric_transformation {
    name      = "NACLChanges"
    namespace = "MyApp/Security"
    value     = "1"