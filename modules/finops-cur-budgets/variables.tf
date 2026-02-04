variable "management_region" {
  type        = string
  default     = "us-east-1"
  description = "Home region for CUR, Budgets, and related resources."
}

variable "finops_email" {
  type        = string
  description = "Email address for FinOps alerts and notifications"
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to resources"
}

variable "product_tag_value" {
  type        = string
  description = "Product tag value for tag-scoped budgets (e.g. 'loan-origination')."
  default     = "loan-origination"
}
