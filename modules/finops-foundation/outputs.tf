output "default_tags" {
  description = "Default tags exported for use in other modules"
  value       = var.default_tags
}

output "finops_email" {
  description = "FinOps email for SNS subscriptions"
  value       = var.finops_email
}

output "platform_admin_role_arn" {
  description = "ARN of the PlatformAdminRole"
  value       = aws_iam_role.platform_admin.arn
}
