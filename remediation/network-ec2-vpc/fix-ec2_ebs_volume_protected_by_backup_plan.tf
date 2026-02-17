#
# Remediate the finding: "EBS volume is protected by a backup plan"
#

# Ensure the EBS volume is included in an AWS Backup plan
resource "aws_backup_selection" "remediation_ebs_volume_backup" {
  name         = "remediation-ebs-volume-backup"
  iam_role_arn = var.aws_backup_role_arn
  plan_id      = aws_backup_plan.remediation_ebs_volume_backup_plan.id

  resources = [
    "arn:aws:ec2:ap-northeast-2:${data.aws_caller_identity.current.account_id}:volume/vol-0278f268cad754e55",
  ]
}

resource "aws_backup_plan" "remediation_ebs_volume_backup_plan" {
  name = "remediation-ebs-volume-backup-plan"

  rule {
    rule_name         = "remediation-ebs-volume-backup-rule"
    target_vault_name = aws_backup_vault.remediation_ebs_volume_backup_vault.name
    schedule          = "cron(0 5 ? * MON *)"
    start_window      = 60
    completion_window = 360
    lifecycle {
      delete_after = 35
    }
  }

  advanced_backup_setting {
    resource_type = "EBS"
    backup_options = {
      encryption_mode = "CUSTOMER_MANAGED"
      kms_key_arn     = var.kms_key_arn
    }
  }
}

resource "aws_backup_vault" "remediation_ebs_volume_backup_vault" {
  name        = "remediation-ebs-volume-backup-vault"
  kms_key_arn = var.kms_key_arn
}

# Set the required variables
variable "aws_backup_role_arn" {
  type        = string
  description = "ARN of the IAM role for AWS Backup"
  default     = ""
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key for encrypting the backup"
  default     = ""
}
