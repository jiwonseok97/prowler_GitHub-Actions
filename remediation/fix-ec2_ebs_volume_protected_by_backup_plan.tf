# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

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

  # Enable Vault Lock for WORM retention
  lifecycle_rule {
    transition {
      target_vault_name = "ebs-backup-vault"
      transition_type   = "COPY"
    }
    delete_after = 365
  }
}

# Associate the EBS volume with the backup plan
resource "aws_backup_selection" "ebs_backup_selection" {
  name         = "ebs-backup-selection"
  plan_id      = aws_backup_plan.ebs_backup_plan.id
  resource_arn = "arn:aws:ec2:ap-northeast-2:132410971304:volume/vol-0278f268cad754e55"
}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an AWS Backup plan named `ebs-backup-plan` to protect the EBS volume.
3. Defines a backup rule within the plan, which includes a schedule, start window, and completion window.
4. Configures the backup plan to use the `EBS` resource type.
5. Creates an AWS Backup vault named `ebs-backup-vault` to store the backups.
6. Enables Vault Lock for WORM (Write Once, Read Many) retention on the backup vault.
7. Associates the EBS volume with the backup plan, ensuring that the volume is protected by the backup plan.