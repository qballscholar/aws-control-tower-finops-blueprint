resource "aws_iam_role" "config_aggregator" {
  name = "AWSConfigAggregatorRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "config_aggregator" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "config:Get*",
      "config:Describe*",
      "config:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "config_aggregator" {
  role   = aws_iam_role.config_aggregator.id
  policy = data.aws_iam_policy_document.config_aggregator.json
}

resource "aws_config_configuration_aggregator" "org" {
  name = "org-aggregator"

  organization_aggregation_source {
    role_arn    = aws_iam_role.config_aggregator.arn
    all_regions = true
  }
}