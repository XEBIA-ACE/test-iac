#
# KMS key for S3 SSE-KMS — aligned with SVC-01 AES-256 PII-at-rest requirement.
# The key is used for both the primary data bucket and the access-log bucket.
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Normalise the bucket base name
  bucket_base = "${var.bucket_name_prefix}-${var.environment}"
}

# ── KMS Key Policy ─────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "kms_policy" {
  # Root-account full access (required for key management recovery)
  statement {
    sid    = "AllowRootAccountFullAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Designated key administrators
  dynamic "statement" {
    for_each = length(var.kms_key_administrators) > 0 ? [1] : []
    content {
      sid    = "AllowKeyAdministrators"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.kms_key_administrators
      }
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
      ]
      resources = ["*"]
    }
  }

  # User Service task role — encrypt/decrypt/re-encrypt
  statement {
    sid    = "AllowUserServiceRole"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.user_service_role_arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]
  }

  # S3 service principal — required for SSE-KMS bucket operations
  statement {
    sid    = "AllowS3ServiceUseOfKey"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }

  # CloudWatch Logs — for log group encryption (if used)
  statement {
    sid    = "AllowCloudWatchLogsUseOfKey"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.region}:${local.account_id}:*"]
    }
  }
}

resource "aws_kms_key" "user_svc_s3" {
  description              = "KMS key for User Service S3 bucket SSE — PII at-rest encryption"
  deletion_window_in_days  = var.kms_deletion_window_days
  enable_key_rotation      = true
  multi_region             = false
  policy                   = data.aws_iam_policy_document.kms_policy.json

  tags = {
    Name    = "${local.bucket_base}-s3-kms"
    Purpose = "s3-sse-user-service-pii"
  }
}

resource "aws_kms_alias" "user_svc_s3" {
  name          = "alias/${local.bucket_base}-s3"
  target_key_id = aws_kms_key.user_svc_s3.key_id
}