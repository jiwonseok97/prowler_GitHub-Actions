# Create a new AWS Organizations AI Services Opt-Out Policy
resource "aws_organizations_policy" "remediation_ai_services_opt_out_policy" {
  name        = "AI Services Opt-Out Policy"
  description = "Opt out of all AI services and prohibit child account overrides"
  content     = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Action" : [
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
          "lookoutforvision:*"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:RequestedRegion" : "ap-northeast-2"
          }
        }
      }
    ]
  })
}

# Attach the AI Services Opt-Out Policy to the root of the AWS Organization
resource "aws_organizations_policy_attachment" "remediation_ai_services_opt_out_policy_attachment" {
  policy_id = aws_organizations_policy.remediation_ai_services_opt_out_policy.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

data "aws_organizations_organization" "current" {
}