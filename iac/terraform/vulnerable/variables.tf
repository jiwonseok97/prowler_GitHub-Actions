variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "name_prefix" {
  description = "Prefix for all vulnerable resource names"
  type        = string
  default     = "vuln-demo"
}
