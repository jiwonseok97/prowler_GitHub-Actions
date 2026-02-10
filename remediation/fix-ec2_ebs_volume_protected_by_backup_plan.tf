# Create an IAM role for the AWS Backup service
resource "aws_iam_role" "remediation_backup_role" {
  name = "remediation-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required managed policy to the IAM role
resource "aws_iam_role_policy_attachment" "remediation_backup_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.remediation_backup_role.name
}

# Create an AWS Backup plan to protect the EBS volume
resource "aws_backup_plan" "remediation_backup_plan" {
  name = "remediation-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.remediation_backup_vault.name
    schedule          = "cron(0 5 ? * MON-FRI *)"
    start_window      = 60
    completion_window = 360
  }

  tags = {
    Environment = "production"
  }
}

# Create an AWS Backup vault to store the backups
resource "aws_backup_vault" "remediation_backup_vault" {
  name = "remediation-backup-vault"

  lifecycle {
    prevent_destroy = true
  }

  kms_key_arn = aws_kms_key.remediation_backup_kms_key.arn
}

# Create a KMS key to encrypt the backups
resource "aws_kms_key" "remediation_backup_kms_key" {
  description             = "KMS key for remediation backup vault"
  deletion_window_in_days = 10
}

# Assign the EBS volume to the backup plan
resource "aws_backup_selection" "remediation_backup_selection" {
  name         = "remediation-backup-selection"
  plan_id      = aws_backup_plan.remediation_backup_plan.id
  iam_role_arn = aws_iam_role.remediation_backup_role.arn
  resources    = [
    "arn:aws:ec2:ap-northeast-2:132410971304:volume/vol-0278f268cad754e55"
  ]
}