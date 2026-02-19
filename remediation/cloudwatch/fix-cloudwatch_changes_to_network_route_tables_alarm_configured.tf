# CIS 1.4 CloudWatch Metric Filters & Alarms
# Each CIS check requires its own metric filter + alarm pair.
# Shared infrastructure: log group + SNS topic (defined once).

variable "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group receiving CloudTrail events (leave empty to use /cloudtrail/remediation)"
  type        = string
  default     = ""
}

# Create the log group only if no existing one is provided.
# Name matches cloudtrail.tf so both workspaces target the same group.
resource "aws_cloudwatch_log_group" "remediation_cis_cloudtrail" {
  count             = var.cloudwatch_log_group_name != "" ? 0 : 1
  name              = "cloudtrail-remediation"
  retention_in_days = 365
}

locals {
  cis_log_group_name = var.cloudwatch_log_group_name != "" ? var.cloudwatch_log_group_name : aws_cloudwatch_log_group.remediation_cis_cloudtrail[0].name
}

# ── Shared: SNS topic for all CIS alarms ──
resource "aws_sns_topic" "remediation_cis_alarms" {
  name = "remediation-cis-cloudwatch-alarms"
}

resource "aws_sns_topic_policy" "remediation_cis_alarms" {
  arn = aws_sns_topic.remediation_cis_alarms.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudWatchAlarms"
      Effect    = "Allow"
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = "SNS:Publish"
      Resource  = aws_sns_topic.remediation_cis_alarms.arn
    }]
  })
}

# ── CIS 3.1: Unauthorized API calls ──
resource "aws_cloudwatch_log_metric_filter" "remediation_unauthorized_api_calls" {
  name           = "cis-unauthorized-api-calls"
  pattern        = "{ ($.errorCode = \"*UnauthorizedAccess\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "UnauthorizedAPICalls"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_unauthorized_api_calls" {
  alarm_name          = "cis-unauthorized-api-calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.1 - Unauthorized API calls detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.2: Sign-in without MFA ──
resource "aws_cloudwatch_log_metric_filter" "remediation_sign_in_without_mfa" {
  name           = "cis-sign-in-without-mfa"
  pattern        = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "SignInWithoutMFA"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_sign_in_without_mfa" {
  alarm_name          = "cis-sign-in-without-mfa"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SignInWithoutMFA"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.2 - Console sign-in without MFA"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.3: Root account usage ──
resource "aws_cloudwatch_log_metric_filter" "remediation_root_usage" {
  name           = "cis-root-usage"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "RootAccountUsage"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_root_usage" {
  alarm_name          = "cis-root-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.3 - Root account usage detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.4: IAM policy changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_iam_policy_changes" {
  name           = "cis-iam-policy-changes"
  pattern        = "{ ($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_iam_policy_changes" {
  alarm_name          = "cis-iam-policy-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMPolicyChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.4 - IAM policy changes detected"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.5: CloudTrail configuration changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_cloudtrail_config_changes" {
  name           = "cis-cloudtrail-config-changes"
  pattern        = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "CloudTrailConfigChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_cloudtrail_config_changes" {
  alarm_name          = "cis-cloudtrail-config-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CloudTrailConfigChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.5 - CloudTrail configuration changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.6: Console authentication failures ──
resource "aws_cloudwatch_log_metric_filter" "remediation_authentication_failures" {
  name           = "cis-authentication-failures"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "ConsoleAuthFailures"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_authentication_failures" {
  alarm_name          = "cis-authentication-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsoleAuthFailures"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.6 - Console authentication failures"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.7: Disable/scheduled deletion of KMS CMKs ──
resource "aws_cloudwatch_log_metric_filter" "remediation_kms_cmk_deletion" {
  name           = "cis-kms-cmk-deletion"
  pattern        = "{ ($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey) || ($.eventName=ScheduleKeyDeletion)) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "KMSCMKDeletion"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_kms_cmk_deletion" {
  alarm_name          = "cis-kms-cmk-deletion"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "KMSCMKDeletion"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.7 - KMS CMK disable or scheduled deletion"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.8: S3 bucket policy changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_s3_bucket_policy_changes" {
  name           = "cis-s3-bucket-policy-changes"
  pattern        = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "S3BucketPolicyChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_s3_bucket_policy_changes" {
  alarm_name          = "cis-s3-bucket-policy-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "S3BucketPolicyChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.8 - S3 bucket policy changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.9: AWS Config configuration changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_aws_config_changes" {
  name           = "cis-aws-config-changes"
  pattern        = "{ ($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder) || ($.eventName=DeleteDeliveryChannel) || ($.eventName=PutDeliveryChannel) || ($.eventName=PutConfigurationRecorder)) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "AWSConfigChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_aws_config_changes" {
  alarm_name          = "cis-aws-config-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "AWSConfigChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.9 - AWS Config configuration changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.10: Security group changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_security_group_changes" {
  name           = "cis-security-group-changes"
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_security_group_changes" {
  alarm_name          = "cis-security-group-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SecurityGroupChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.10 - Security group changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.11: Network ACL changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_network_acl_changes" {
  name           = "cis-network-acl-changes"
  pattern        = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "NetworkACLChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_network_acl_changes" {
  alarm_name          = "cis-network-acl-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkACLChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.11 - Network ACL changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.12: Network gateway changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_network_gateway_changes" {
  name           = "cis-network-gateway-changes"
  pattern        = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "NetworkGatewayChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_network_gateway_changes" {
  alarm_name          = "cis-network-gateway-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkGatewayChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.12 - Network gateway changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.13: Route table changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_route_table_changes" {
  name           = "cis-route-table-changes"
  pattern        = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "RouteTableChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_route_table_changes" {
  alarm_name          = "cis-route-table-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RouteTableChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.13 - Route table changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS 3.14: VPC changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_vpc_changes" {
  name           = "cis-vpc-changes"
  pattern        = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "VPCChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_vpc_changes" {
  alarm_name          = "cis-vpc-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "VPCChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS 3.14 - VPC changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}

# ── CIS: AWS Organizations changes ──
resource "aws_cloudwatch_log_metric_filter" "remediation_organizations_changes" {
  name           = "cis-organizations-changes"
  pattern        = "{ ($.eventSource = organizations.amazonaws.com) && (($.eventName = AcceptHandshake) || ($.eventName = AttachPolicy) || ($.eventName = CreateAccount) || ($.eventName = CreateOrganizationalUnit) || ($.eventName = CreatePolicy) || ($.eventName = DeclineHandshake) || ($.eventName = DeleteOrganization) || ($.eventName = DeleteOrganizationalUnit) || ($.eventName = DeletePolicy) || ($.eventName = DetachPolicy) || ($.eventName = DisablePolicyType) || ($.eventName = EnablePolicyType) || ($.eventName = InviteAccountToOrganization) || ($.eventName = LeaveOrganization) || ($.eventName = MoveAccount) || ($.eventName = RemoveAccountFromOrganization) || ($.eventName = UpdatePolicy) || ($.eventName = UpdateOrganizationalUnit)) }"
  log_group_name = local.cis_log_group_name

  metric_transformation {
    name      = "OrganizationsChanges"
    namespace = "CIS/CloudWatch"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "remediation_organizations_changes" {
  alarm_name          = "cis-organizations-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "OrganizationsChanges"
  namespace           = "CIS/CloudWatch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CIS - AWS Organizations changes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.remediation_cis_alarms.arn]
}
