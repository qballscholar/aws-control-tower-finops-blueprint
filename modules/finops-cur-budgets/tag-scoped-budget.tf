variable "product_tag_value" {
  type        = string
  description = "Product tag value (e.g. 'loan-origination')."
}

resource "aws_budgets_budget" "product_monthly" {
  name        = "prod-${var.product_tag_value}-monthly"
  budget_type = "COST"
  time_unit   = "MONTHLY"

  limit_amount = "2000"
  limit_unit   = "USD"

  cost_filters = {
    "TagKeyValue" = ["Product$${var.product_tag_value}"]
  }

  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.finops_budgets.arn]
  }
}