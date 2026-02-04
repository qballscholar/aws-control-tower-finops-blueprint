resource "aws_s3_bucket" "cur" {
  bucket = "finops-cur-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.default_tags, {
    Purpose = "cur-storage"
  })
}

resource "aws_s3_bucket_public_access_block" "cur" {
  bucket = aws_s3_bucket.cur.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cur" {
  bucket = aws_s3_bucket.cur.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cur_report_definition" "org_cur" {
  report_name = "org-finops-cur"

  time_unit   = "HOURLY"
  format      = "textORcsv"
  compression = "GZIP"

  additional_schema_elements = [
    "RESOURCES"
  ]

  s3_bucket = aws_s3_bucket.cur.bucket
  s3_region = var.management_region
  s3_prefix = "cur/"

  report_versioning    = "CREATE_NEW_REPORT"
  additional_artifacts = ["ATHENA"]
}