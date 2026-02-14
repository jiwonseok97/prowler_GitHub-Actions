# TODO: Manual remediation required for config_recorder_all_regions_enabled
# Title: AWS Config recorder is enabled and not in failure state or disabled
# Last validation error: ::error::Terraform exited with code 1.   Error: Reference to undeclared resource    on candidate.tf line 13, in resource "aws_config_configuration_recorder_status" "remediation_config_recorder_status"
resource "null_resource" "remediation_config_recorder_all_regions_enabled" {
  triggers = {
    check_id     = "config_recorder_all_regions_enabled"
    resource_uid = "arn:aws:config:ap-northeast-2:132410971304:recorder"
  }
}
