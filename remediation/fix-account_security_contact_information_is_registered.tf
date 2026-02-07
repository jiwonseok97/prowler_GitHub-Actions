# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Create an AWS IAM account alias
resource "aws_iam_account_alias" "security_alias" {
  account_alias = "security-contact-${data.aws_caller_identity.current.account_id}"
}

# Create an AWS IAM user for the security contact
resource "aws_iam_user" "security_contact" {
  name = "security-contact"
}

# Create an AWS IAM access key for the security contact user
resource "aws_iam_access_key" "security_contact_key" {
  user = aws_iam_user.security_contact.name
}

# Create an AWS SNS topic for security notifications
resource "aws_sns_topic" "security_notifications" {
  name = "security-notifications-${data.aws_caller_identity.current.account_id}"
}

# Subscribe the security contact user to the security notifications topic
resource "aws_sns_topic_subscription" "security_contact_subscription" {
  topic_arn = aws_sns_topic.security_notifications.arn
  protocol  = "email"
  endpoint  = aws_iam_user.security_contact.name
}