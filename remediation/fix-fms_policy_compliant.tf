# Configure the AWS provider for the ap-northeast-2 region

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
        "ResourceARN": "arn:aws:network-firewall:ap-northeast-2:132410971304:stateless-rulegroup/example-stateless-rulegroup"
      }
    ],
    "StatelessDefaultActions": [
      "aws:drop"
    ],
    "StatelessFragmentDefaultActions": [
      "aws:drop"
    ]
  }
}
POLICY
  tags = {
    Environment = "production"
  }
}


# This Terraform code creates a new Firewall Manager (FMS) policy in the `ap-northeast-2` region. The policy is configured to use a Network Firewall policy, which includes a reference to a stateless rule group. The policy is set to be remediation-enabled, meaning that it will automatically remediate any non-compliant resources. The code also includes a tag for the "Environment" of the policy.