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
