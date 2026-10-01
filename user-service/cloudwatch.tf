#
# CloudWatch alarms for operational visibility over the S3 bucket.
# Alarms fire on: abnormal 4xx/5xx error rates and unusually high request volumes.
#

resource "aws_cloudwatch_metric_alarm" "s3_4xx_errors" {
  alarm_name          = "${local.bucket_base}-s3-4xx-errors"
  alarm_description   = "User Service S3 bucket is returning elevated 4xx errors (access/auth issues)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = module.s3_user_service.s3_bucket_id
    StorageType = "AllStorageTypes"
  }

  tags = {
    Name = "${local.bucket_base}-s3-4xx-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_5xx_errors" {
  alarm_name          = "${local.bucket_base}-s3-5xx-errors"
  alarm_description   = "User Service S3 bucket is returning 5xx server-side errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = module.s3_user_service.s3_bucket_id
    StorageType = "AllStorageTypes"
  }

  tags = {
    Name = "${local.bucket_base}-s3-5xx-alarm"
  }
}