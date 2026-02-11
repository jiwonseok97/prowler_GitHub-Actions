variable "aws_region" {
  default = "ap-northeast-2"
}

variable "account_id" {
  default = "132410971304"
}

variable "role_name" {
  default = "GitHubActionsProwlerRole"
}

variable "state_bucket" {
  default = "prowler-terraform-state-132410971304"
}

variable "lock_table" {
  default = "prowler-terraform-locks"
}

variable "extra_policy_arns" {
  type    = list(string)
  default = []
}

variable "bedrock_model_arns" {
  type = list(string)
  default = [
    "arn:aws:bedrock:ap-northeast-2::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
    "arn:aws:bedrock:ap-northeast-2::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
  ]
}
