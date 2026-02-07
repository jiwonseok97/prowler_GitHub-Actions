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
  "PolicyOption": {
    "NetworkFirewallPolicy": true
  }
}
POLICY
  include_map = {
    "ACCOUNT" = ["132410971304"]
  }
}


This Terraform code creates a new Firewall Manager (FMS) policy in the `ap-northeast-2` region. The policy is configured to use a Network Firewall policy, which includes a reference to a stateless rule group. The policy is set to be automatically remediated, and it is applied to the specified AWS account.