output "cost_category_id" {
  description = "Cost category ID"
  value       = aws_ce_cost_category.application.id
}

output "cost_category_arn" {
  description = "Cost category ARN"
  value       = aws_ce_cost_category.application.arn
}
