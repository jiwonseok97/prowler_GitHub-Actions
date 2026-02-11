variable "s3_enable_remediation" {
  type    = bool
  default = false
}

variable "s3_target_bucket_name" {
  type    = string
  default = ""
}

variable "s3_logging_bucket_name" {
  type    = string
  default = ""
}

variable "s3_create_logging_bucket" {
  type    = bool
  default = false
}

variable "s3_enable_bucket_acl" {
  type    = bool
  default = false
}

variable "s3_enable_mfa_delete" {
  type    = bool
  default = false
}

variable "s3_mfa_serial" {
  type    = string
  default = ""
}

variable "s3_mfa_token" {
  type    = string
  default = ""
}

variable "s3_enable_cloudtrail" {
  type    = bool
  default = false
}

variable "s3_create_kms_key" {
  type    = bool
  default = false
}

variable "s3_kms_key_arn" {
  type    = string
  default = ""
}

variable "s3_create_logging_kms_key" {
  type    = bool
  default = false
}

variable "s3_logging_kms_key_arn" {
  type    = string
  default = ""
}

locals {
  s3_target_enabled       = var.s3_enable_remediation && var.s3_target_bucket_name != ""
  s3_create_logging       = var.s3_enable_remediation && var.s3_create_logging_bucket && var.s3_logging_bucket_name != ""
  s3_use_existing_logging = var.s3_enable_remediation && !var.s3_create_logging_bucket && var.s3_logging_bucket_name != ""
  s3_logging_enabled      = local.s3_create_logging || local.s3_use_existing_logging
  s3_do_mfa_delete         = local.s3_target_enabled && var.s3_enable_mfa_delete && var.s3_mfa_serial != "" && var.s3_mfa_token != ""
}

data "aws_s3_bucket" "s3_target" {
  count  = local.s3_target_enabled ? 1 : 0
  bucket = var.s3_target_bucket_name
}

data "aws_s3_bucket" "s3_logging" {
  count  = local.s3_use_existing_logging ? 1 : 0
  bucket = var.s3_logging_bucket_name
}

resource "aws_s3_bucket" "s3_logging" {
  count  = local.s3_create_logging ? 1 : 0
  bucket = var.s3_logging_bucket_name
}

locals {
  s3_target_bucket_id  = local.s3_target_enabled ? data.aws_s3_bucket.s3_target[0].id : ""
  s3_target_bucket_arn = local.s3_target_enabled ? data.aws_s3_bucket.s3_target[0].arn : ""

  s3_logging_bucket_id = local.s3_create_logging ? aws_s3_bucket.s3_logging[0].id :
    (local.s3_use_existing_logging ? data.aws_s3_bucket.s3_logging[0].id : "")
  s3_logging_bucket_arn = local.s3_create_logging ? aws_s3_bucket.s3_logging[0].arn :
    (local.s3_use_existing_logging ? data.aws_s3_bucket.s3_logging[0].arn : "")
}
