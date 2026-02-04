# Product Account Configuration - Example: prod-app1-account
# 
# This file wires a product account into the shared FinOps infrastructure.
# Unlike the management account, product accounts:
# - Do NOT deploy finops-foundation or finops-org (those are org-level)
# - DO inherit default_tags from the management account
# - DO reference shared SNS topics from management account
# - CAN have their own Config rules and cost tracking

# NOTE: Before using this configuration:
# 1. Create the account in AWS Organizations (from management account)
# 2. Update the account_id variable below with the actual account ID
# 3. Set the product_name to match your product/application
# 4. Run from the management account context or with cross-account assume role

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source to get management account details (for cross-account references)
data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "org" {}

# Variable for the product/application name
variable "product_name" {
  type        = string
  description = "Name of the product or application (e.g., 'loan-origination', 'payments')"
  default     = "app1"
}

# Variable for management account ID (to reference shared resources)
variable "management_account_id" {
  type        = string
  description = "AWS Account ID of the management/payer account"
  # Example: "123456789012"
}

# Variable for management region
variable "management_region" {
  type        = string
  default     = "us-east-1"
  description = "Home region where management account resources are deployed"
}

# Product-specific tags
variable "product_tags" {
  type        = map(string)
  description = "Product-specific tags to override or supplement default tags"
  default = {
    CostCenter  = "PRODUCT"
    Environment = "production"
    Owner       = "product-team"
    Product     = "app1"
  }
}

# Merge default tags with product-specific tags
locals {
  product_tags = merge(
    var.product_tags,
    {
      ManagedBy = "terraform"
      CreatedBy = "finops-blueprint"
    }
  )
}

# ===================================================================
# AWS Config Setup (Product Account Level)
# ===================================================================
# Deploy Config recorder to this product account for compliance tracking
# Inherits organization-level Config aggregator from management account

module "finops_config_product" {
  source = "../../modules/finops-config"

  management_region = var.management_region
  default_tags      = local.product_tags
}

# ===================================================================
# Cost Tracking & Budgets (Product Account Level)
# ===================================================================
# Track product-specific costs and set budget alerts
# References SNS topics from management account for centralized alerting

# To use this, you need to pass the SNS topic ARN from management account
# Either:
# 1. Use a data source to look it up by name
# 2. Pass it via module variable
# 3. Use remote state to reference management account outputs

module "finops_cur_budgets_product" {
  source = "../../modules/finops-cur-budgets"

  management_region   = var.management_region
  finops_email        = "product-team@company.com"  # ← Change to product team email
  default_tags        = local.product_tags
  product_tag_value   = var.product_name
}

# ===================================================================
# Cost Categories (Optional - Product Level)
# ===================================================================
# If tracking product-specific cost dimensions locally
# (otherwise use org-level cost categories from management account)

module "finops_cost_categories_product" {
  source = "../../modules/finops-cost-categories"

  default_tags = local.product_tags
}

# ===================================================================
# Outputs - References for dashboard/monitoring integrations
# ===================================================================

output "config_bucket_name" {
  description = "S3 bucket name for Config recordings"
  value       = module.finops_config_product.config_bucket_name
}

output "config_recorder_id" {
  description = "Config recorder ID"
  value       = module.finops_config_product.config_recorder_id
}

output "cur_bucket_name" {
  description = "S3 bucket name for product CUR data"
  value       = module.finops_cur_budgets_product.cur_bucket_name
}

output "product_budget_id" {
  description = "Product-specific budget ID"
  value       = module.finops_cur_budgets_product.product_budget_id
}

output "finops_budgets_topic_arn" {
  description = "SNS topic ARN for product budget alerts"
  value       = module.finops_cur_budgets_product.finops_budgets_topic_arn
}

output "cost_category_id" {
  description = "Cost category ID for this product"
  value       = module.finops_cost_categories_product.cost_category_id
}

output "product_tags" {
  description = "Tags applied to all product resources"
  value       = local.product_tags
}
