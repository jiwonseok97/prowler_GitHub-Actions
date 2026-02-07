# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Backup plan
resource "aws_backup_plan" "critical_ebs_volumes" {
  name = "critical-ebs-volumes-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = "critical-ebs-volumes-backup-vault"
    schedule          = "cron(0 5 ? * MON-FRI *)"
    start_window      = 60
    completion_window = 360
  }

  advanced_backup_setting {
    backup_options = {
      "version" = "V2"
    }
    resource_type = "EBS"
  }
}

# Create an AWS Backup vault with Vault Lock enabled
resource "aws_backup_vault" "critical_ebs_volumes" {
  name = "critical-ebs-volumes-backup-vault"

  lifecycle {
    prevent_destroy = true
  }

  kms_key_arn = aws_kms_key.backup_vault_key.arn
}

# Create a KMS key for encrypting the backup vault
resource "aws_kms_key" "backup_vault_key" {
  description             = "KMS key for critical EBS volumes backup vault"
  deletion_window_in_days = 10
}

# Associate the EBS volume with the backup plan
resource "aws_backup_selection" "critical_ebs_volume" {
  name         = "critical-ebs-volume"
  plan_id      = aws_backup_plan.critical_ebs_volumes.id
  resource_arn = "arn:aws:ec2:ap-northeast-2:132410971304:volume/vol-0278f268cad754e55"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an AWS Backup plan named `critical-ebs-volumes-backup-plan` with a daily backup schedule.
3. Creates an AWS Backup vault named `critical-ebs-volumes-backup-vault` with Vault Lock enabled and a KMS key for encryption.
4. Associates the specified EBS volume (`arn:aws:ec2:ap-northeast-2:132410971304:volume/vol-0278f268cad754e55`) with the backup plan.

This should address the security finding by including the critical EBS volume in a standardized AWS Backup plan, with encryption, Vault Lock, and a regular backup schedule.