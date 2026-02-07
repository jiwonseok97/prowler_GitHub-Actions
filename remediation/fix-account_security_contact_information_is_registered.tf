# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an IAM account alias for the security contact
resource "aws_iam_account_alias" "security_contact" {
  account_alias = "security-contact"
}

# Create an IAM user for the security contact
resource "aws_iam_user" "security_contact" {
  name = "security-contact"
}

# Create an IAM access key for the security contact user
resource "aws_iam_access_key" "security_contact" {
  user = aws_iam_user.security_contact.name
}

# Create an SNS topic for security notifications
resource "aws_sns_topic" "security_notifications" {
  name = "security-notifications"
}

# Create an SNS subscription for the security contact
resource "aws_sns_topic_subscription" "security_contact" {
  topic_arn = aws_sns_topic.security_notifications.arn
  protocol  = "email"
  endpoint  = "security@example.com"
}