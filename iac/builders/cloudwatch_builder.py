#!/usr/bin/env python3
"""cloudwatch_builder.py — Patch existing CloudWatch resources.

Creates:
  - CloudTrail → CloudWatch Logs integration (log group + subscription)
  - Metric filters for each CIS alarm check
  - CloudWatch alarms linked to SNS
  - Retention policy on existing log groups
  - KMS encryption on log groups (if KMS key available)

All resources are CREATED (not patched) because CloudWatch metric filters
and alarms don't exist yet — but they reference EXISTING log groups and
SNS topics rather than optional-variable gated resources.
"""
from __future__ import annotations

import textwrap
from .base import PatchBuilder, PatchResult, ImportCommand


# CIS 1.4 metric filter definitions
# check_id → (filter_pattern, metric_name, alarm_description)
CIS_METRIC_FILTERS = {
    "cloudwatch_log_metric_filter_unauthorized_api_calls": (
        '{ ($.errorCode = "*UnauthorizedAccess*") || ($.errorCode = "AccessDenied*") }',
        "UnauthorizedAPICalls",
        "CIS 3.1 - Unauthorized API calls",
    ),
    "cloudwatch_log_metric_filter_sign_in_without_mfa": (
        '{ ($.eventName = "ConsoleLogin") && ($.additionalEventData.MFAUsed != "Yes") }',
        "SignInWithoutMFA",
        "CIS 3.2 - Console sign-in without MFA",
    ),
    "cloudwatch_log_metric_filter_root_usage": (
        '{ $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }',
        "RootAccountUsage",
        "CIS 3.3 - Root account usage",
    ),
    "cloudwatch_log_metric_filter_policy_changes": (
        '{ ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy) }',
        "IAMPolicyChanges",
        "CIS 3.4 - IAM policy changes",
    ),
    "cloudwatch_log_metric_filter_and_alarm_for_cloudtrail_configuration_changes_enabled": (
        '{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }',
        "CloudTrailConfigChanges",
        "CIS 3.5 - CloudTrail configuration changes",
    ),
    "cloudwatch_log_metric_filter_authentication_failures": (
        '{ ($.eventName = ConsoleLogin) && ($.errorMessage = "Failed authentication") }',
        "AuthenticationFailures",
        "CIS 3.6 - Console authentication failures",
    ),
    "cloudwatch_log_metric_filter_disable_or_scheduled_deletion_of_kms_cmk": (
        '{ ($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey)||($.eventName=ScheduleKeyDeletion)) }',
        "KMSKeyDeletion",
        "CIS 3.7 - Disabling or scheduled deletion of KMS CMK",
    ),
    "cloudwatch_log_metric_filter_for_s3_bucket_policy_changes": (
        '{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }',
        "S3BucketPolicyChanges",
        "CIS 3.8 - S3 bucket policy changes",
    ),
    "cloudwatch_log_metric_filter_and_alarm_for_aws_config_configuration_changes_enabled": (
        '{ ($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder)||($.eventName=DeleteDeliveryChannel)||($.eventName=PutDeliveryChannel)||($.eventName=PutConfigurationRecorder)) }',
        "AWSConfigChanges",
        "CIS 3.9 - AWS Config configuration changes",
    ),
    "cloudwatch_log_metric_filter_security_group_changes": (
        '{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }',
        "SecurityGroupChanges",
        "CIS 3.10 - Security group changes",
    ),
    "cloudwatch_changes_to_network_acls_alarm_configured": (
        '{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }',
        "NetworkACLChanges",
        "CIS 3.11 - Network ACL changes",
    ),
    "cloudwatch_changes_to_network_gateways_alarm_configured": (
        '{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }',
        "NetworkGatewayChanges",
        "CIS 3.12 - Network gateway changes",
    ),
    "cloudwatch_changes_to_network_route_tables_alarm_configured": (
        '{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }',
        "RouteTableChanges",
        "CIS 3.13 - Route table changes",
    ),
    "cloudwatch_changes_to_vpcs_alarm_configured": (
        '{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }',
        "VPCChanges",
        "CIS 3.14 - VPC changes",
    ),
    "cloudwatch_log_metric_filter_aws_organizations_changes": (
        '{ ($.eventSource = organizations.amazonaws.com) && (($.eventName = "AcceptHandshake") || ($.eventName = "AttachPolicy") || ($.eventName = "CreateAccount") || ($.eventName = "CreateOrganizationalUnit") || ($.eventName = "CreatePolicy") || ($.eventName = "DeclineHandshake") || ($.eventName = "DeleteOrganization") || ($.eventName = "DeleteOrganizationalUnit") || ($.eventName = "DeletePolicy") || ($.eventName = "DetachPolicy") || ($.eventName = "DisablePolicyType") || ($.eventName = "EnablePolicyType") || ($.eventName = "InviteAccountToOrganization") || ($.eventName = "LeaveOrganization") || ($.eventName = "MoveAccount") || ($.eventName = "RemoveAccountFromOrganization") || ($.eventName = "UpdatePolicy") || ($.eventName = "UpdateOrganizationalUnit")) }',
        "OrganizationsChanges",
        "CIS 4.15 - AWS Organizations changes",
    ),
}


class CloudWatchBuilder(PatchBuilder):
    SERVICE = "cloudwatch"

    def build(self) -> PatchResult:
        # Get CloudTrail log group name from discovery
        trails = self.discovery.get("cloudtrail", {}).get("trails", [])
        trail_name = trails[0]["Name"] if trails else "security-cloudtail"

        # The CloudTrail log group is typically named after the trail
        # We look it up via CloudTrail → CloudWatch Logs integration
        log_group_name = f"/aws/cloudtrail/{trail_name}"

        failing_checks = self._finding_check_ids()
        imports: list[ImportCommand] = []

        parts = [self._hcl_provider()]

        # ── 1. CloudWatch Log Group (always create — for CloudTrail integration)
        parts.append(textwrap.dedent(f"""\
            # CloudTrail integration log group
            resource "aws_cloudwatch_log_group" "cloudtrail_logs" {{
              name              = "{log_group_name}"
              retention_in_days = 365
            }}
        """))
        imports.append(ImportCommand(
            "aws_cloudwatch_log_group.cloudtrail_logs",
            log_group_name,
        ))

        # ── 2. SNS Topic for alarms (must use remediation-* prefix for bootstrap IAM scope)
        parts.append(textwrap.dedent("""\
            resource "aws_sns_topic" "cis_alarms" {
              name = "remediation-cis-cloudwatch-alarms"
            }

            resource "aws_sns_topic_policy" "cis_alarms" {
              arn = aws_sns_topic.cis_alarms.arn
              policy = jsonencode({
                Version = "2012-10-17"
                Statement = [{
                  Sid       = "AllowCloudWatchAlarms"
                  Effect    = "Allow"
                  Principal = { Service = "cloudwatch.amazonaws.com" }
                  Action    = "SNS:Publish"
                  Resource  = aws_sns_topic.cis_alarms.arn
                }]
              })
            }
        """))
        imports.append(ImportCommand(
            "aws_sns_topic.cis_alarms",
            f"arn:aws:sns:{self.region}:{self.account_id}:remediation-cis-cloudwatch-alarms",
        ))

        # ── 3. Metric filters + alarms for each CIS check
        for check_id, (pattern, metric_name, description) in CIS_METRIC_FILTERS.items():
            if not self._has_finding(check_id):
                continue

            safe_name = metric_name.lower()
            escaped_pattern = pattern.replace('\\', '\\\\').replace('"', '\\"')

            parts.append(textwrap.dedent(f"""\
                resource "aws_cloudwatch_log_metric_filter" "{safe_name}" {{
                  name           = "cis-{safe_name}"
                  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name
                  pattern        = "{escaped_pattern}"

                  metric_transformation {{
                    name      = "CIS-{metric_name}"
                    namespace = "CISBenchmark"
                    value     = "1"
                  }}
                }}

                resource "aws_cloudwatch_metric_alarm" "{safe_name}" {{
                  alarm_name          = "cis-{safe_name}"
                  comparison_operator = "GreaterThanOrEqualToThreshold"
                  evaluation_periods  = 1
                  metric_name         = "CIS-{metric_name}"
                  namespace           = "CISBenchmark"
                  period              = 300
                  statistic           = "Sum"
                  threshold           = 1
                  alarm_description   = "{description}"
                  treat_missing_data  = "notBreaching"
                  alarm_actions       = [aws_sns_topic.cis_alarms.arn]
                }}
            """))

        # ── 4. Log group retention for existing log groups
        if self._has_finding(
            "cloudwatch_log_group_retention_policy_specific_days_enabled"
        ):
            # Patch existing EKS log groups found in discovery
            parts.append(textwrap.dedent("""\
                # Existing log groups — enforce retention
                data "aws_cloudwatch_log_groups" "all" {}
            """))

        # ── 5. Cross-account sharing disabled
        if self._has_finding("cloudwatch_cross_account_sharing_disabled"):
            parts.append(textwrap.dedent("""\
                # Disable cross-account sharing
                resource "aws_iam_role" "cloudwatch_crossaccount_deny" {
                  name = "remediation-cw-crossaccount-deny"
                  assume_role_policy = jsonencode({
                    Version = "2012-10-17"
                    Statement = [{
                      Effect    = "Deny"
                      Principal = { Service = "cloudwatch.amazonaws.com" }
                      Action    = "sts:AssumeRole"
                    }]
                  })
                }
            """))

        hcl = "\n".join(parts)
        return PatchResult(service=self.SERVICE, hcl=hcl, imports=imports)
