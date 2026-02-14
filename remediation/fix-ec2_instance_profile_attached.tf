# TODO: Manual remediation required for ec2_instance_profile_attached
# Title: EC2 instance is associated with an IAM instance profile role
# Last validation error: ::error::Terraform exited with code 1.   Error: Invalid resource type    on candidate.tf line 6, in resource "aws_ec2_instance" "remediation_instance":    6: resource "aws_ec2_instance" "remediation_i
resource "null_resource" "remediation_ec2_instance_profile_attached" {
  triggers = {
    check_id     = "ec2_instance_profile_attached"
    resource_uid = "arn:aws:ec2:ap-northeast-2:132410971304:instance/i-0fbecaba3c48e7c79"
  }
}
