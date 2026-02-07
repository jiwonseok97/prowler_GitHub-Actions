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
        "translate:*",
        "polly:*",
        "transcribe:*",
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


The provided Terraform code does the following:

1. Configures the AWS provider for the `ap-northeast-2` region.
2. Creates an AWS Organizations Service Control Policy (SCP) named "AI Services Opt-Out" that denies access to all AI-related services.
3. Attaches the "AI Services Opt-Out" policy to the root of the AWS Organization, ensuring that the policy is applied to all child accounts and cannot be overridden.

This code addresses the security finding by establishing an organization-wide AI services opt-out policy, aligning with the principles of least privilege and data minimization.