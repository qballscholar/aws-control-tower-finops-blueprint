output "config_recorder_id" {
  description = "Config recorder ID"
  value       = aws_config_configuration_recorder.org.id
}

output "config_bucket_name" {
  description = "S3 bucket name for Config"
  value       = aws_s3_bucket.config.bucket
}

output "aggregator_arn" {
  description = "Config aggregator ARN"
  value       = aws_config_configuration_aggregator.org.arn
}

output "required_tags_rule_id" {
  description = "Required tags Config rule ID"
  value       = aws_config_config_rule.required_tags.id
}

output "approved_regions_rule_id" {
  description = "Approved regions Config rule ID"
  value       = aws_config_config_rule.approved_regions.id
}
