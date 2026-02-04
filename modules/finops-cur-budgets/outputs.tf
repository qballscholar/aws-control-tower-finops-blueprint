output "cur_bucket_name" {
  description = "S3 bucket name for CUR"
  value       = aws_s3_bucket.cur.bucket
}

output "cur_report_name" {
  description = "CUR report definition name"
  value       = aws_cur_report_definition.org_cur.report_name
}

output "finops_budgets_topic_arn" {
  description = "SNS topic ARN for budget alerts"
  value       = aws_sns_topic.finops_budgets.arn
}

output "finops_anomalies_topic_arn" {
  description = "SNS topic ARN for cost anomalies"
  value       = aws_sns_topic.finops_anomalies.arn
}

output "account_budget_id" {
  description = "Account-level monthly budget ID"
  value       = aws_budgets_budget.account_monthly.id
}

output "product_budget_id" {
  description = "Product-level monthly budget ID"
  value       = aws_budgets_budget.product_monthly.id
}
