resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "controltower.amazonaws.com",
    "config.amazonaws.com",
    "cloudtrail.amazonaws.com"
  ]

  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organization.this.roots.id
}

resource "aws_organizations_organizational_unit" "non_prod" {
  name      = "NonProd"
  parent_id = aws_organizations_organization.this.roots.id
}

# Add more OUs for BUs or shared services as needed.