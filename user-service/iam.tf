#
# IAM resources for S3 bucket access — principle of least privilege.
#
# Resources created:
#   1. Bucket policy (attached via s3.tf module argument)
#   2. IAM policy for User Service task role (read/write)
#   3. IAM policy for reader roles (read-only)
#

# ── Bucket Policy Document ─────────────────────────────────────────────────────
data "aws_iam_policy_document" "bucket_policy" {

  # Allow User Service task role full read/write on the bucket
  statement {
    sid    = "AllowUserServiceReadWrite"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.user_service_role_arn]
    }
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_base}",
      "arn:aws:s3:::${local.bucket_base}/*",
    ]
  }

  # Allow additional read-only roles (e.g., audit, analytics)
  dynamic "statement" {
    for_each = length(var.additional_reader_role_arns) > 0 ? [1] : []
    content {
      sid    = "AllowReadOnlyAccess"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.additional_reader_role_arns
      }
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectTagging",
        "s3:ListBucket",
        "s3:GetBucketLocation",
      ]
      resources = [
        "arn:aws:s3:::${local.bucket_base}",
        "arn:aws:s3:::${local.bucket_base}/*",
      ]
    }
  }

  # Explicit deny for any principal that is not in the approved list
  # (defence-in-depth; the public access block is the primary guard)
  statement {
    sid    = "DenyAllOtherPrincipals"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_base}",
      "arn:aws:s3:::${local.bucket_base}/*",
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values = concat(
        [var.user_service_role_arn],
        var.additional_reader_role_arns,
        # Root account — for break-glass scenarios
        ["arn:aws:iam::${local.account_id}:root"],
      )
    }
  }
}

# ── IAM Policy: User Service read/write ─────────────────────────────────────────
resource "aws_iam_policy" "user_service_s3_readwrite" {
  name        = "${local.bucket_base}-s3-readwrite"
  description = "Grants the User Service (SVC-01) task role read/write access to the primary S3 bucket and use of its KMS key"
  path        = "/shopping-app/user-service/"

  policy = data.aws_iam_policy_document.user_service_s3_readwrite.json
}

data "aws_iam_policy_document" "user_service_s3_readwrite" {
  # S3 object-level operations
  statement {
    sid    = "S3ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:GetObjectAcl",
    ]
    resources = ["arn:aws:s3:::${local.bucket_base}/*"]
  }

  # S3 bucket-level listing
  statement {
    sid    = "S3BucketList"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
    ]
    resources = ["arn:aws:s3:::${local.bucket_base}"]
  }

  # KMS: generate and decrypt data keys for SSE-KMS
  statement {
    sid    = "KMSDecryptEncrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = [aws_kms_key.user_svc_s3.arn]
  }
}

# Attach the read/write policy to the User Service role
resource "aws_iam_role_policy_attachment" "user_service_s3_readwrite" {
  role       = element(split("/", var.user_service_role_arn), length(split("/", var.user_service_role_arn)) - 1)
  policy_arn = aws_iam_policy.user_service_s3_readwrite.arn
}

# ── IAM Policy: Read-only (audit / analytics roles) ───────────────────────────
resource "aws_iam_policy" "user_service_s3_readonly" {
  name        = "${local.bucket_base}-s3-readonly"
  description = "Grants read-only access to the User Service S3 bucket (audit, analytics)"
  path        = "/shopping-app/user-service/"

  policy = data.aws_iam_policy_document.user_service_s3_readonly.json
}

data "aws_iam_policy_document" "user_service_s3_readonly" {
  statement {
    sid    = "S3ReadOnly"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_base}",
      "arn:aws:s3:::${local.bucket_base}/*",
    ]
  }

  statement {
    sid    = "KMSDecryptReadOnly"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [aws_kms_key.user_svc_s3.arn]
  }
}