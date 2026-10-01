#
# Access-log bucket (receives server-access logs for the primary bucket).
# Must be created before the primary bucket.
#

module "s3_access_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.16.1"

  bucket = "${local.bucket_base}-access-logs"

  # Security — block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Ownership
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # Versioning
  versioning = {
    enabled = true
  }

  # Encryption with the same KMS key
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.user_svc_s3.arn
      }
    }
  }

  # Enforce TLS-only transport
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  # Access-log bucket cannot also log to itself; no logging block here.

  # Lifecycle — prune old access logs
  lifecycle_rule = [
    {
      id      = "access-log-retention"
      enabled = true

      abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_days

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
      ]

      noncurrent_version_expiration = {
        noncurrent_days = 30
      }

      expiration = {
        days = 180
      }
    },
  ]

  tags = {
    Name    = "${local.bucket_base}-access-logs"
    Purpose = "s3-access-logs"
  }
}

# ── Primary User Service bucket ────────────────────────────────────────────────

module "s3_user_service" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.16.1"

  bucket = local.bucket_base

  # ── Block all public access ─────────────────────────────────────────────────
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # ── Ownership ───────────────────────────────────────────────────────────────
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # ── Versioning ──────────────────────────────────────────────────────────────
  versioning = {
    enabled = true
  }

  # ── SSE-KMS encryption (AES-256 via KMS) ────────────────────────────────────
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.user_svc_s3.arn
      }
    }
  }

  # ── Access logging ──────────────────────────────────────────────────────────
  logging = {
    target_bucket = module.s3_access_logs.s3_bucket_id
    target_prefix = "user-service-primary/"
  }

  # ── Bucket policies ─────────────────────────────────────────────────────────
  # Deny non-TLS transport (enforces HTTPS-only)
  attach_deny_insecure_transport_policy = true
  # Require minimum TLS 1.2
  attach_require_latest_tls_policy = true
  # Deny unencrypted (non-SSE-KMS) object uploads
  attach_deny_unencrypted_object_uploads = true
  # Deny uploads that do not use the approved KMS key
  attach_deny_incorrect_kms_key_sse = true
  allowed_kms_key_arn                = aws_kms_key.user_svc_s3.arn
  # Deny incorrect encryption headers
  attach_deny_incorrect_encryption_headers = true

  # Custom IAM bucket policy (least-privilege for User Service + optional readers)
  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json

  # ── Lifecycle rules ─────────────────────────────────────────────────────────
  lifecycle_rule = concat(
    [
      {
        id      = "standard-tiering"
        enabled = true

        abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_days

        transition = [
          {
            days          = var.transition_ia_days
            storage_class = "STANDARD_IA"
          },
          {
            days          = var.transition_glacier_days
            storage_class = "GLACIER"
          },
        ]

        noncurrent_version_expiration = {
          noncurrent_days           = var.noncurrent_version_expiration_days
          newer_noncurrent_versions = 3
        }

        noncurrent_version_transition = [
          {
            noncurrent_days = 30
            storage_class   = "STANDARD_IA"
          },
          {
            noncurrent_days = 60
            storage_class   = "GLACIER"
          },
        ]
      },
    ],
    var.expiration_days > 0 ? [
      {
        id      = "object-expiration"
        enabled = true
        expiration = {
          days = var.expiration_days
        }
      },
    ] : []
  )

  tags = {
    Name    = "${local.bucket_base}-primary"
    Purpose = "user-service-object-storage"
    DataClassification = "PII"
  }
}