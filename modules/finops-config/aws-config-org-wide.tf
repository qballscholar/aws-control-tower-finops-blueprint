resource "aws_iam_role" "config_role" {
  name = "AWSConfigRoleOrg"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "config_role" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
      "config:*",
      "ec2:Describe*",
      "rds:Describe*",
      "iam:Get*",
      "iam:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "config_role" {
  role   = aws_iam_role.config_role.id
  policy = data.aws_iam_policy_document.config_role.json
}

resource "aws_s3_bucket" "config" {
  bucket = "org-config-${data.aws_caller_identity.current.account_id}"
}

resource "aws_config_configuration_recorder" "org" {
  name     = "org-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "org" {
  name           = "org-delivery"
  s3_bucket_name = aws_s3_bucket.config.bucket

  depends_on = [aws_config_configuration_recorder.org]
}

resource "aws_config_configuration_recorder_status" "org" {
  name       = aws_config_configuration_recorder.org.name
  is_enabled = true
}
