# =============================================================================
# Intentionally Vulnerable Infrastructure — Demo Only
# Prowler CIS 1.4 E2E Remediation Pipeline Demo
#
# 이 파일은 Prowler 스캔 → AI 자동 remediation PR → apply → 취약점 해소
# 파이프라인을 시연하기 위해 의도적으로 취약한 설정을 적용합니다.
# =============================================================================

terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket         = "prowler-terraform-state-132410971304"
    key            = "vulnerable/demo.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "prowler-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  prefix     = var.name_prefix
}

# =============================================================================
# [IAM] 취약: 비밀번호 정책 — 최소 기준 미달
# Prowler checks: iam_password_policy_minimum_length_14,
#   iam_password_policy_number, iam_password_policy_symbol,
#   iam_password_policy_uppercase, iam_password_policy_reuse_24,
#   iam_password_policy_expires_passwords_within_90_days_or_less
# =============================================================================
resource "aws_iam_account_password_policy" "weak" {
  minimum_password_length      = 8    # FAIL: < 14
  require_uppercase_characters = false # FAIL
  require_lowercase_characters = true
  require_numbers              = false # FAIL
  require_symbols              = false # FAIL
  allow_users_to_change_password = true
  hard_expiry                  = false
  password_reuse_prevention    = 0    # FAIL: < 24
  max_password_age             = 0    # FAIL: 0 = never expires
}

# =============================================================================
# [S3] 취약: 암호화 없음, 버전관리 없음, 퍼블릭 액세스 차단 없음
# Prowler checks: s3_bucket_default_encryption,
#   s3_bucket_object_versioning, s3_bucket_acl_prohibited,
#   s3_bucket_secure_transport_policy, s3_bucket_server_access_logging_enabled
# =============================================================================
resource "aws_s3_bucket" "vuln_demo" {
  bucket        = "${local.prefix}-vuln-demo-${local.account_id}"
  force_destroy = true

  tags = {
    Name    = "${local.prefix}-vuln-demo"
    Purpose = "security-demo-vulnerable"
  }
}

# 암호화 없음 — 기본 상태 (no server-side encryption)

# 버전관리 비활성화
resource "aws_s3_bucket_versioning" "vuln_demo" {
  bucket = aws_s3_bucket.vuln_demo.id
  versioning_configuration {
    status = "Suspended" # FAIL: should be Enabled
  }
}

# 퍼블릭 액세스 차단 비활성화
resource "aws_s3_bucket_public_access_block" "vuln_demo" {
  bucket                  = aws_s3_bucket.vuln_demo.id
  block_public_acls       = false # FAIL
  ignore_public_acls      = false # FAIL
  block_public_policy     = false # FAIL
  restrict_public_buckets = false # FAIL
}

# 소유권 설정 (ACL 사용 허용 — FAIL for s3_bucket_acl_prohibited)
resource "aws_s3_bucket_ownership_controls" "vuln_demo" {
  bucket = aws_s3_bucket.vuln_demo.id
  rule {
    object_ownership = "BucketOwnerPreferred" # FAIL: should be BucketOwnerEnforced
  }
}

# =============================================================================
# [CloudTrail] 취약: 로그 파일 검증 없음, KMS 암호화 없음
# Prowler checks: cloudtrail_log_file_validation_enabled,
#   cloudtrail_kms_encryption_enabled
# =============================================================================

# CloudTrail 로그 저장용 S3 버킷
resource "aws_s3_bucket" "trail_vuln" {
  bucket        = "${local.prefix}-trail-vuln-${local.account_id}"
  force_destroy = true

  tags = {
    Name    = "${local.prefix}-trail-vuln"
    Purpose = "security-demo-vulnerable"
  }
}

resource "aws_s3_bucket_public_access_block" "trail_vuln" {
  bucket                  = aws_s3_bucket.trail_vuln.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# CloudTrail이 버킷에 쓸 수 있도록 버킷 정책 허용
resource "aws_s3_bucket_policy" "trail_vuln" {
  bucket = aws_s3_bucket.trail_vuln.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.trail_vuln.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.trail_vuln.arn}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 취약한 CloudTrail: 검증 없음, KMS 없음
resource "aws_cloudtrail" "vuln_trail" {
  name                          = "${local.prefix}-vuln-trail"
  s3_bucket_name                = aws_s3_bucket.trail_vuln.id
  is_multi_region_trail         = false # FAIL: should be true
  enable_log_file_validation    = false # FAIL: CIS requires true
  include_global_service_events = true
  # kms_key_id 없음 — FAIL: cloudtrail_kms_encryption_enabled

  depends_on = [aws_s3_bucket_policy.trail_vuln]

  tags = {
    Name    = "${local.prefix}-vuln-trail"
    Purpose = "security-demo-vulnerable"
  }
}

# =============================================================================
# [Network/VPC] 취약: VPC Flow Logs 없음
# Prowler check: vpc_flow_logs_enabled
# =============================================================================
resource "aws_vpc" "vuln_demo" {
  cidr_block           = "10.99.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  # Flow Logs 없음 — FAIL: vpc_flow_logs_enabled

  tags = {
    Name    = "${local.prefix}-vuln-vpc"
    Purpose = "security-demo-vulnerable"
  }
}

resource "aws_subnet" "vuln_demo" {
  vpc_id            = aws_vpc.vuln_demo.id
  cidr_block        = "10.99.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.prefix}-vuln-subnet"
  }
}

# 기본 보안 그룹은 AWS가 자동 생성 (모든 outbound 허용 상태)
# Flow Logs는 의도적으로 생성하지 않음 → vpc_flow_logs_enabled FAIL

# =============================================================================
# [CloudWatch] 취약: CIS 메트릭 필터 없음
# Prowler checks: cloudwatch_log_metric_filter_* (15개)
# → CloudTrail과 연동된 로그 그룹에 메트릭 필터가 없으면 모두 FAIL
# 별도 리소스 생성 없이 이미 부재(absence)로 FAIL 발생
# =============================================================================
# (의도적으로 아무 CloudWatch 메트릭 필터도 생성하지 않음)
