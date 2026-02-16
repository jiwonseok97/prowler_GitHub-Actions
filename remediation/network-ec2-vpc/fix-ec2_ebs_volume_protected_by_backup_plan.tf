#
# Remediate the finding: "EBS volume is protected by a backup plan"
#

resource "aws_backup_vault" "remediation_backup_vault" {
  name = "remediation-backup-vault"
}

resource "aws_backup_plan" "remediation_backup_plan" {
  name = "remediation-backup-plan"

  rule {
    rule_name         = "remediation-backup-rule"
    target_vault_name = aws_backup_vault.remediation_backup_vault.name
    schedule          = "cron(0 5 ? * MON *)"
    start_window      = 60
    completion_window = 360
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_backup_selection" "remediation_backup_selection" {
  name         = "remediation-backup-selection"
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-backup-service-role"
  plan_id      = aws_backup_plan.remediation_backup_plan.id

  resources = [
    "arn:aws:ec2:ap-northeast-2:${data.aws_caller_identity.current.account_id}:volume/vol-0278f268cad754e55",
  ]
}
