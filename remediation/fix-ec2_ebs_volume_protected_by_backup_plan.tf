# TODO: Manual remediation required for ec2_ebs_volume_protected_by_backup_plan
# Title: EBS volume is protected by a backup plan
# Last validation error: init failed: ::error::Terraform exited with code 1.  Terraform encountered problems during initialisation, including problems with the configuration, described below.  The Terraform configuration must
resource "null_resource" "remediation_ec2_ebs_volume_protected_by_backup_plan" {
  triggers = {
    check_id     = "ec2_ebs_volume_protected_by_backup_plan"
    resource_uid = "arn:aws:ec2:ap-northeast-2:132410971304:volume/vol-0278f268cad754e55"
  }
}
