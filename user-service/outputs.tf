# ── Primary Bucket ─────────────────────────────────────────────────────────────
output "bucket_id" {
  description = "Name (ID) of the primary User Service S3 bucket"
  value       = module.s3_user_service.s3_bucket_id
}

output "bucket_arn" {
  description = "ARN of the primary User Service S3 bucket"
  value       = module.s3_user_service.s3_bucket_arn
}

output "bucket_region" {
  description = "AWS region the primary bucket resides in"
  value       = module.s3_user_service.s3_bucket_region
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = module.s3_user_service.s3_bucket_bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Region-specific S3 bucket domain name"
  value       = module.s3_user_service.s3_bucket_bucket_regional_domain_name
}

output "bucket_versioning_status" {
  description = "Versioning status of the primary bucket"
  value       = module.s3_user_service.aws_s3_bucket_versioning_status
}

# ── Access Log Bucket ──────────────────────────────────────────────────────────
output "access_log_bucket_id" {
  description = "Name (ID) of the S3 access-log bucket"
  value       = module.s3_access_logs.s3_bucket_id
}

output "access_log_bucket_arn" {
  description = "ARN of the S3 access-log bucket"
  value       = module.s3_access_logs.s3_bucket_arn
}

# ── KMS ────────────────────────────────────────────────────────────────────────
output "kms_key_arn" {
  description = "ARN of the KMS key used for S3 SSE-KMS encryption"
  value       = aws_kms_key.user_svc_s3.arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for S3 SSE-KMS encryption"
  value       = aws_kms_key.user_svc_s3.key_id
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.user_svc_s3.name
}

# ── IAM ────────────────────────────────────────────────────────────────────────
output "iam_policy_readwrite_arn" {
  description = "ARN of the IAM policy granting User Service read/write access to S3 + KMS"
  value       = aws_iam_policy.user_service_s3_readwrite.arn
}

output "iam_policy_readonly_arn" {
  description = "ARN of the IAM policy granting read-only access to S3 + KMS (audit/analytics)"
  value       = aws_iam_policy.user_service_s3_readonly.arn
}