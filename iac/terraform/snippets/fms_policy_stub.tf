# Firewall Manager policy stub (example)
# NOTE: Replace with your actual policy details
resource "aws_fms_policy" "example" {
  name        = "org-mandatory-policy"
  resource_type = "AWS::ElasticLoadBalancingV2::LoadBalancer"
  remediation_enabled = true
  exclude_resource_tags = false

  security_service_policy_data {
    type = "WAFV2"
    managed_service_data = jsonencode({
      type = "WAFV2"
    })
  }
}
