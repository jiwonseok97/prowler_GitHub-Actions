#
# Remediate the finding: "EBS volume is protected by a backup plan"
#

resource "aws_backup_vault" "remediation_backup_vault" {
  name = "remediation-backup-vault"
}

resource "aws_backup_plan" "remediation_backup_plan" {
  name = "remediation-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.remediation_backup_vault.name
    schedule          = "cron(0 5 ? * * *)"
    start_window      = 60
    completion_window = 360
  }
}

resource "aws_backup_selection" "remediation_backup_selection" {
  name         = "remediation-backup-selection"
  iam_role_arn = var.iam_role_arn
  plan_id      = aws_backup_plan.remediation_backup_plan.id
  resources    = [var.ebs_volume_id]
}


variable "iam_role_arn" {
  description = "IAM role ARN for AWS Backup"
  type        = string
  default     = ""
}

variable "ebs_volume_id" {
  description = "ebs_volume_id"
  type        = string
  default     = ""
}
