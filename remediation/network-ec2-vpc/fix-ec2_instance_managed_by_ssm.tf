#Enroll the EC2 instance as a Systems Manager managed node
resource "aws_ssm_association" "remediation_ssm_association" {
  name = "AmazonSSMManagedInstanceCore"
}

#Attach the AmazonSSMManagedInstanceCore policy to the instance's IAM role

#Ensure the instance has the required IAM instance profile
data "aws_iam_instance_profile" "current" {
  name = "i-0fbecaba3c48e7c79"
}
