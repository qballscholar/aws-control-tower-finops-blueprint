resource "aws_sns_topic" "finops_anomalies" {
  name = "finops-cost-anomalies"

  tags = merge(var.default_tags, {
    Purpose = "cost-anomaly-alerts"
  })
}

resource "aws_sns_topic_subscription" "finops_anomalies_email" {
  topic_arn = aws_sns_topic.finops_anomalies.arn
  protocol  = "email"
  endpoint  = var.finops_email
}

# Configure AWS Cost Anomaly Detection in the console to send notifications to finops_anomalies.