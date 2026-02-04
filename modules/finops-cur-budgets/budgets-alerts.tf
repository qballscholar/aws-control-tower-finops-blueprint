resource "aws_sns_topic" "finops_budgets" {
  name = "finops-budgets-alerts"

  tags = merge(var.default_tags, {
    Purpose = "budget-alerts"
  })
}

resource "aws_sns_topic_subscription" "finops_budgets_email" {
  topic_arn = aws_sns_topic.finops_budgets.arn
  protocol  = "email"
  endpoint  = var.finops_email
}

resource "aws_budgets_budget" "account_monthly" {
  name        = "acct-${data.aws_caller_identity.current.account_id}-monthly"
  budget_type = "COST"
  time_unit   = "MONTHLY"

  limit_amount = "5000"
  limit_unit   = "USD"

  cost_filters = {
    "LinkedAccount" = [data.aws_caller_identity.current.account_id]
  }

  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.finops_budgets.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.finops_budgets.arn]
  }
}