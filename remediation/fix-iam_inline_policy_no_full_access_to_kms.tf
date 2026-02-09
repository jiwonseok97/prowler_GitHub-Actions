provider "aws" {
  region = "ap-northeast-2"
}

# Create a new IAM policy with least-privilege permissions for KMS
data "aws_kms_key" "example_key" {
  key_arn = "arn:aws:kms:ap-northeast-2:132410971304:key/example-key-id"
}

resource "aws_iam_policy" "kms_access_policy" {
  name        = "kms-access-policy"
  description = "Least-privilege permissions for KMS"

  policy = <<EOF