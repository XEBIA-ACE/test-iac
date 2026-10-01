variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "project_id" {
  description = "Project identifier for tagging (from architecture context)"
  type        = string
  default     = "4fb4b4a8-b925-4acd-9a7e-d7b9d3373134"
}

variable "org_id" {
  description = "Organisation identifier for tagging (from architecture context)"
  type        = string
  default     = "95bd4e80-e002-4fe5-ab71-fa85aad9fec8"
}

# ── Bucket naming ──────────────────────────────────────────────────────────────
variable "bucket_name_prefix" {
  description = "Prefix for the S3 bucket name. A unique suffix is appended automatically."
  type        = string
  default     = "shopping-app-user-svc"
}

# ── Access ─────────────────────────────────────────────────────────────────────
variable "user_service_role_arn" {
  description = "IAM role ARN used by the User Service ECS/EKS task that needs read/write access to the bucket"
  type        = string
  # No default — must be supplied at apply time
}

variable "additional_reader_role_arns" {
  description = "Optional additional IAM role ARNs granted read-only access (e.g., audit, analytics)"
  type        = list(string)
  default     = []
}

# ── KMS ────────────────────────────────────────────────────────────────────────
variable "kms_key_administrators" {
  description = "List of IAM ARNs (users/roles) that can administer the KMS key"
  type        = list(string)
  default     = []
}

variable "kms_deletion_window_days" {
  description = "Number of days before KMS key is deleted after scheduling deletion"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "kms_deletion_window_days must be between 7 and 30."
  }
}

# ── Lifecycle ─────────────────────────────────────────────────────────────────
variable "noncurrent_version_expiration_days" {
  description = "Number of days after which non-current object versions are expired"
  type        = number
  default     = 90
}

variable "transition_ia_days" {
  description = "Days before current-version objects transition to STANDARD_IA"
  type        = number
  default     = 30
}

variable "transition_glacier_days" {
  description = "Days before current-version objects transition to GLACIER"
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Days before current-version objects are permanently deleted (0 = never)"
  type        = number
  default     = 0
}

variable "abort_incomplete_multipart_days" {
  description = "Days after which incomplete multipart uploads are aborted"
  type        = number
  default     = 7
}