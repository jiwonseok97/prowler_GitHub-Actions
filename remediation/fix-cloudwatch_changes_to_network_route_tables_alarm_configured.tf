provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter to capture VPC route table changes
resource "aws_cloudwatch_log_metric_filter" "vpc_route_table_changes" {
  name           = "vpc-route-table-changes"
  pattern        = "{$.eventName = CreateRoute} || {$.eventName = CreateRouteTable} || {$.eventName = ReplaceRoute} || {$.eventName = ReplaceRouteTableAssociation} || {$.eventName = DeleteRouteTable} || {$.eventName = DeleteRoute} || {$.eventName = AssociateRouteTable} || {$.eventName = DisassociateRouteTable}"
  log_group_name = data.aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "VPCRouteTableChanges"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"