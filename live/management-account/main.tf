# This file wires your management (payer) account into the shared FinOps modules:

module "finops_foundation" {
  source = "../../modules/finops-foundation"

  management_region            = "us-east-1"
  platform_admin_principal_arn = "arn:aws:iam::123456789012:role/OrgAdmin"
  finops_email                 = "finops@your-org.com"
}

module "finops_org" {
  source = "../../modules/finops-org"

  management_region = "us-east-1"
  default_tags      = module.finops_foundation.default_tags
}

module "finops_config" {
  source = "../../modules/finops-config"

  management_region = "us-east-1"
  default_tags      = module.finops_foundation.default_tags
}

module "finops_cur_budgets" {
  source = "../../modules/finops-cur-budgets"

  management_region = "us-east-1"
  finops_email      = module.finops_foundation.finops_email
  default_tags      = module.finops_foundation.default_tags
}

module "finops_cost_categories" {
  source = "../../modules/finops-cost-categories"

  default_tags = module.finops_foundation.default_tags
}

#Customize when scaling out

# New BU or product → add an OU and account in modules/finops-org, then create a live/<account>/main.tf referencing finops-config and finops-cur-budgets.
# New cost dimensions → extend rules in modules/finops-cost-categories and dashboards/queries.
