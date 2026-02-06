# Configure the AWS provider for the ap-northeast-2 region
provider "aws" {
  region = "ap-northeast-2"
}

# Create an AWS Config Delivery Channel
resource "aws_config_delivery_channel" "config_delivery_channel" {
  name           = "config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.id
}

# Create an S3 bucket for storing AWS Config logs
resource "aws_s3_bucket" "config_bucket" {
  bucket = "my-config-bucket"
  acl    = "private"
}

# Create an AWS Config Configuration Recorder
resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Create an IAM role for the AWS Config Recorder
resource "aws_iam_role" "config_role" {
  name = "config-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the required AWS Config managed policy to the IAM role
resource "aws_iam_role_policy_attachment" "config_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
  role       = aws_iam_role.config_role.name
}


This Terraform code will:

1. Configure the AWS provider for the `ap-northeast-2` region.
2. Create an AWS Config Delivery Channel to deliver the configuration logs to an S3 bucket.
3. Create an S3 bucket to store the AWS Config logs.
4. Create an AWS Config Configuration Recorder to record the configuration changes in all supported regions and resource types.
5. Create an IAM role for the AWS Config Recorder and attach the required managed policy to the role.