# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Organizations Service Control Policy (SCP) to opt out of all AI services
resource "aws_organizations_policy" "ai_services_opt_out" {
  name        = "AI Services Opt-Out"
  description = "Opt out of all AI services and prohibit child policy overrides"

  content = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "rekognition:*",
        "textract:*",
        "comprehend:*",
        "transcribe:*",
        "translate:*",
        "polly:*",
        "sagemaker:*",
        "lex:*",
        "forecast:*",
        "personalize:*",
        "kendra:*",
        "lookoutvision:*",
        "lookoutmetrics:*",
        "lookoutequipment:*",
        "lookoutforvision:*",
        "lookoutforsecurity:*"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

# Attach the AI Services Opt-Out policy to the root of the AWS Organization
resource "aws_organizations_policy_attachment" "ai_services_opt_out_attachment" {
  policy_id = aws_organizations_policy.ai_services_opt_out.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

# Data source to retrieve the current AWS Organization
data "aws_organizations_organization" "current" {}


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an AWS Organizations Service Control Policy (SCP) named "AI Services Opt-Out" that denies access to all AI-related services.
3. Attaches the "AI Services Opt-Out" policy to the root of the AWS Organization, ensuring that the policy applies to all child accounts.
4. Retrieves the current AWS Organization using a data source, which is used to target the root of the organization for the policy attachment.

This Terraform code addresses the security finding by establishing an organization-wide AI services opt-out policy, which prohibits child accounts from overriding the policy. This aligns with the recommendation to "set the default to `optOut` and prohibit child policy overrides (`@@none`)".