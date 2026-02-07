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
        lifecycle = {
          delete_after = 30
        }
      }
    }
  }
}

# Create an AWS Backup vault with Vault Lock enabled
resource "aws_backup_vault" "critical_ebs_volumes" {
  name = "critical-ebs-volumes-backup-vault"

  # Enable Vault Lock for WORM retention
  lifecycle_rule {
    rule_name = "worm-retention"
    enable_rule_lock = true
    delete_after = 3650 # 10 years
  }
}

# Assign the EBS volume to the backup plan
resource "aws_backup_selection" "critical_ebs_volume" {
  name          = "critical-ebs-volume"
  iam_role_arn  = aws_iam_role.backup_role.arn
  plan_id       = aws_backup_plan.critical_ebs_volumes.id

  resources = [
    "arn:aws:ec2:ap-northeast-2:132410971304:volume/vol-0278f268cad754e55"
  ]
}

# Create an IAM role for the AWS Backup service
resource "aws_iam_role" "backup_role" {
  name = "backup-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "backup.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach the required permissions to the IAM role
resource "aws_iam_role_policy_attachment" "backup_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}


This Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an AWS Backup plan named `critical-ebs-volumes-backup-plan` with a daily backup schedule.
3. Creates an AWS Backup vault named `critical-ebs-volumes-backup-vault` with Vault Lock enabled for 10-year WORM retention.
4. Assigns the specified EBS volume to the backup plan using the `aws_backup_selection` resource.
5. Creates an IAM role named `backup-role` with the necessary permissions for the AWS Backup service.