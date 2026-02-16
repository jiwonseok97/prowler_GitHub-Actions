#Create an AWS Backup plan to protect the EBS volume
resource "aws_backup_plan" "remediation_backup_plan" {
  name = "remediation-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.remediation_backup_vault.name
    schedule          = "cron(0 5 ? * MON-FRI *)"
    start_window      = 60
    completion_window = 120

    lifecycle {
      delete_after = 35
    }
  }

  tags = {
    Environment = "production"
  }
}

#Create an AWS Backup vault to store the backups
resource "aws_backup_vault" "remediation_backup_vault" {
  name = "remediation-backup-vault"

  kms_key_arn = aws_kms_key.remediation_backup_key.arn
}

#Create a KMS key to encrypt the backups
resource "aws_kms_key" "remediation_backup_key" {
  description             = "Remediation Backup Key"
  deletion_window_in_days = 10
}

#Assign the EBS volume to the backup plan
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
