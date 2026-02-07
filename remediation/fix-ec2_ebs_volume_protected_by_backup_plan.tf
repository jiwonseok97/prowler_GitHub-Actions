# Configure the AWS provider for the ap-northeast-2 region

# Create an AWS Backup plan to protect the EBS volume
resource "aws_backup_plan" "ebs_backup_plan" {
  name = "ebs-backup-plan"

  rule {
    rule_name         = "ebs-backup-rule"
    target_vault_name = "ebs-backup-vault"
    schedule          = "cron(0 5 ? * MON *)"
    start_window      = 60
    completion_window = 360
  }

  advanced_backup_setting {
    backup_options = {
      "version" = "V1"
    }
    resource_type = "EBS"
  }
}

# Create an AWS Backup vault to store the backups
resource "aws_backup_vault" "ebs_backup_vault" {
  name = "ebs-backup-vault"
}

# Assign the EBS volume to the backup plan
resource "aws_backup_selection" "ebs_backup_selection" {
  name         = "ebs-backup-selection"
  plan_id      = aws_backup_plan.ebs_backup_plan.id
  resource_arn = "arn:aws:ec2:ap-northeast-2:132410971304:volume/vol-0278f268cad754e55"
}


# This Terraform code creates an AWS Backup plan and vault to protect the specified EBS volume. The backup plan is configured to run a weekly backup on Mondays at 5 AM, with a 60-minute start window and a 360-minute completion window. The backups are stored in the "ebs-backup-vault" and the EBS volume is assigned to the backup plan.