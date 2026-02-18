#
# Create an AWS Backup plan to protect the EBS volume
#
resource "aws_backup_plan" "remediation_ebs_backup_plan" {
  name = "remediation-ebs-backup-plan"

  rule {
    rule_name         = "daily-ebs-backup"
    target_vault_name = aws_backup_vault.remediation_ebs_backup_vault.name
    schedule          = "cron(0 5 ? * MON-FRI *)"
    start_window      = 60
    completion_window = 360
    lifecycle {
      delete_after = 35
    }
  }
}

#
# Create an AWS Backup vault to store the EBS volume backups
#
resource "aws_backup_vault" "remediation_ebs_backup_vault" {
  name = "remediation-ebs-backup-vault"
  kms_key_arn = aws_kms_key.remediation_ebs_backup_kms_key.arn
}

#
# Create a KMS key to encrypt the EBS volume backups
#
resource "aws_kms_key" "remediation_ebs_backup_kms_key" {
  description             = "KMS key for EBS volume backups"
  deletion_window_in_days = 10
}

#
# Associate the EBS volume with the backup plan
#
resource "aws_backup_selection" "remediation_ebs_volume_backup_selection" {
  iam_role_arn = var.iam_role_arn
  name = "remediation-ebs-volume-backup-selection"
  plan_id      = aws_backup_plan.remediation_ebs_backup_plan.id
}

variable "iam_role_arn" {
  description = "iam_role_arn"
  type        = string
  default     = ""
}
