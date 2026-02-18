output "s3_vuln_bucket" {
  description = "Vulnerable S3 bucket name"
  value       = aws_s3_bucket.vuln_demo.bucket
}

output "cloudtrail_name" {
  description = "Vulnerable CloudTrail trail name"
  value       = aws_cloudtrail.vuln_trail.name
}

output "vpc_id" {
  description = "Vulnerable VPC ID (no flow logs)"
  value       = aws_vpc.vuln_demo.id
}

output "trail_s3_bucket" {
  description = "CloudTrail log bucket"
  value       = aws_s3_bucket.trail_vuln.bucket
}
