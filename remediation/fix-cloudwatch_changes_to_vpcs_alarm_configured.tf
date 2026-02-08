provider "aws" {
  region = "ap-northeast-2"
}

# Create a CloudWatch Logs metric filter to capture VPC changes
resource "aws_cloudwatch_log_metric_filter" "vpc_changes" {
  name           = "vpc-changes"
  pattern        = "{$.eventSource = ec2.amazonaws.com && $.eventName = CreateVpc || $.eventName = DeleteVpc || $.eventName = ModifyVpcAttribute || $.eventName = AcceptVpcPeeringConnection || $.eventName = CreateVpcPeeringConnection || $.eventName = DeleteVpcPeeringConnection || $.eventName = RejectVpcPeeringConnection}"
  log_group_name = data.aws_cloudwatch_log_group.cloudtrail_log_group.name

  metric_transformation {
    name      = "VPCChanges"
    namespace = "MyApp/SecurityMetrics"
    value     = "1"