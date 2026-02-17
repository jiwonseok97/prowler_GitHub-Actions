# Create an AWS Backup plan to protect the EBS volume
resource "aws_backup_plan" "remediation_backup_plan" {
  name = "remediation-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.remediation_backup_vault.name
    schedule          = "cron(0 5 ? * MON-FRI *)"
    start_window      = 60
    completion_window = 360
  }

  tags = {
    Environment = "production"
    Backup      = "enabled"
  }
}

# Create an AWS Backup vault to store the backups
resource "aws_backup_vault" "remediation_backup_vault" {
  name = "remediation-backup-vault"

  kms_key_arn = aws_kms_key.remediation_kms_key.arn
}

# Create a KMS key to encrypt the backup vault
resource "aws_kms_key" "remediation_kms_key" {
  description             = "Remediation KMS key for Backup Vault"
  deletion_window_in_days = 10
}

# Add the EBS volume to the Backup plan
resource "aws_backup_selection" "remediation_backup_selection" {
  iam_role_arn = var.iam_role_arn
  name = "remediation-backup-selection"
  plan_id      = aws_backup_plan.remediation_backup_plan.id
}

variable "iam_role_arn" {
  description = "iam_role_arn"
  type        = string
  default     = ""
}
