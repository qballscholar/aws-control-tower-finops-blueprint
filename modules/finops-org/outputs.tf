output "organization_id" {
  description = "AWS Organization ID"
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = aws_organizations_organization.this.arn
}

output "root_id" {
  description = "Root organizational unit ID"
  value       = aws_organizations_organization.this.roots[0].id
}

output "prod_ou_id" {
  description = "Production OU ID"
  value       = aws_organizations_organizational_unit.prod.id
}

output "non_prod_ou_id" {
  description = "Non-Production OU ID"
  value       = aws_organizations_organizational_unit.non_prod.id
}

output "scp_baseline_id" {
  description = "SCP baseline policy ID"
  value       = aws_organizations_policy.scp_baseline.id
}
