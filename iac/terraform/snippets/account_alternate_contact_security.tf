# Set the Security alternate contact for the AWS account
resource "aws_account_alternate_contact" "security" {
  alternate_contact_type = "SECURITY"
  email_address          = "security@example.com"
  name                   = "Security Team"
  phone_number           = "+1-555-0100"
  title                  = "Security"
}
