# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new Firewall Manager policy
resource "aws_fms_policy" "example_fms_policy" {
  name = "example-fms-policy"
  remediation_enabled = true
  resource_type = "AWS::EC2::NetworkInterface"
  security_service_policy_data = <<POLICY
{
  "Type": "NETWORK_FIREWALL",
  "NetworkFirewallPolicy": {
    "StatefulRuleGroupReferences": [],
    "StatelessRuleGroupReferences": [
      {
        "ResourceARN": "arn:aws:network-firewall:ap-northeast-2:132410971304:stateless-rulegroup/example-stateless-rule-group"
      }
    ],
    "StatelessDefaultActions": [
      "aws-forwarding-action"
    ],
    "StatelessFragmentDefaultActions": [
      "aws-forwarding-action"
    ]
  },
  "ResourceType": "NETWORK_FIREWALL"
}
POLICY
  security_service_role_arn = "arn:aws:iam::132410971304:role/aws-service-role/fms.amazonaws.com/AWSServiceRoleForFMS"
}


This Terraform code creates a new Firewall Manager (FMS) policy in the `ap-northeast-2` region. The policy is configured to use a Network Firewall security service, with a reference to a stateless rule group. The `remediation_enabled` flag is set to `true`, which means that the policy will automatically remediate any non-compliant resources. The `security_service_role_arn` is set to the ARN of the IAM role that the FMS service uses to manage the policy.