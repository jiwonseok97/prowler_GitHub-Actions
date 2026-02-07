# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create a new Firewall Manager policy
resource "aws_fms_policy" "example_fms_policy" {
  name = "example-fms-policy"
  
  # Set the policy to be compliant with the security finding
  compliance_status = "COMPLIANT"
  
  # Define the policy rules
  policy_update_token = "abc123"
  resource_type       = "AWS_ACCOUNT"
  include_map {
    account = ["*"]
  }
  
  # Enable automatic remediation for the policy
  remediation_enabled = true
  
  # Set the policy to apply to all accounts
  exclude_map {
    account = []
  }
}


This Terraform code creates a new Firewall Manager (FMS) policy in the `ap-northeast-2` region. The policy is set to be compliant with the security finding, and it is configured to apply to all AWS accounts. The `remediation_enabled` parameter is set to `true`, which means that the policy will automatically remediate any non-compliant resources.