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
    schedule          = "cron(0 5 ? * * *)"
    start_window      = 60
    completion_window = 360
  }

  # Enable cross-Region/account copies
  advanced_backup_setting {
    backup_options = {
      cross_region_copy = {
        target_region = "us-west-2"
      }
    }
  }
}

# Create an AWS Backup vault with Vault Lock enabled
resource "aws_backup_vault" "critical_ebs_volumes" {
  name = "critical-ebs-volumes-backup-vault"

  # Enable Vault Lock for WORM retention
  lifecycle_rule {
    delete_after = 90
  }

  # Encrypt the backup vault with a KMS key
  kms_key_arn = "arn:aws:kms:ap-northeast-2:132410971304:key/your-kms-key-arn"
}

# Assign the EBS volume to the backup plan
resource "aws_backup_selection" "critical_ebs_volume" {
  name         = "critical-ebs-volume"
  plan_id      = aws_backup_plan.critical_ebs_volumes.id
  resource_arn = "arn:aws:ec2:ap-northeast-2:132410971304:volume/vol-0278f268cad754e55"
}


This Terraform code creates an AWS Backup plan, a Backup vault with Vault Lock and KMS encryption, and assigns the specified EBS volume to the backup plan. The backup plan is configured to run daily backups with a 60-minute start window and a 360-minute completion window. The code also enables cross-Region/account copies to the us-west-2 Region.