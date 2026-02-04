resource "aws_config_config_rule" "required_tags" {
  name = "required-tags-finops"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = "CostCenter"
    tag2Key = "Environment"
    tag3Key = "Owner"
  })

  scope {
    compliance_resource_types = ["AWS::AllSupported"]
  }

  depends_on = [aws_config_configuration_recorder_status.org]
}

resource "aws_config_config_rule" "approved_regions" {
  name = "approved-regions"

  source {
    owner             = "AWS"
    source_identifier = "REGION_RESTRICTION_CHECK"
  }

  input_parameters = jsonencode({
    allowedRegions = "us-east-1,us-west-2"
  })

  depends_on = [aws_config_configuration_recorder_status.org]
}