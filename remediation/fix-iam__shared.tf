variable "iam_enable_remediation" {
  type    = bool
  default = false
}

variable "iam_unattached_policy_arn" {
  type    = string
  default = ""
}

variable "iam_cloudtrail_policy_arn" {
  type    = string
  default = ""
}

variable "iam_kms_policy_arn" {
  type    = string
  default = ""
}

locals {
  iam_do_unattached = var.iam_enable_remediation && var.iam_unattached_policy_arn != ""
  iam_do_cloudtrail = var.iam_enable_remediation && var.iam_cloudtrail_policy_arn != ""
  iam_do_kms        = var.iam_enable_remediation && var.iam_kms_policy_arn != ""
}
