# Create an AWS Backup plan to protect the EBS volume
resource "aws_backup_plan" "remediation_ebs_backup_plan" {
  name = "remediation-ebs-backup-plan"

  rule {
    rule_name         = "daily-ebs-backup"
    target_vault_name = "remediation-ebs-backup-vault"
    schedule          = "cron(0 5 ? * MON-FRI *)"
    start_window      = 60
    completion_window = 120

    lifecycle {
      delete_after = 35
    }
  }
}

# Create an AWS Backup vault to store the EBS volume backups
resource "aws_backup_vault" "remediation_ebs_backup_vault" {
  name = "remediation-ebs-backup-vault"
}

# Associate the EBS volume with the AWS Backup plan
resource "aws_backup_selection" "remediation_ebs_backup_selection" {
  name         = "remediation-ebs-backup-selection"
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/backup.amazonaws.com/AWSBackupDefaultServiceRole"
  plan_id      = aws_backup_plan.remediation_ebs_backup_plan.id

  resources = [
    "arn:aws:ec2:ap-northeast-2:${data.aws_caller_identity.current.account_id}:volume/vol-0278f268cad754e55",
  ]
}
