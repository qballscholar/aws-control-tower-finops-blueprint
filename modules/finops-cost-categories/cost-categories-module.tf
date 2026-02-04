resource "aws_ce_cost_category" "application" {
  name         = "Application"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = "LoanOrigination"

    rule {
      and {
        dimension {
          key           = "LINKED_ACCOUNT"
          values        = [data.aws_caller_identity.current.account_id]
          match_options = ["EQUALS"]
        }
        tags {
          key    = "Product"
          values = ["loan-origination"]
        }
      }
    }
  }

  default_value = "Other"
}
# Add more rules for other products/BUs.