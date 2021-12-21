resource "aws_sns_topic" "webhook_emailer_topic" {
  name = "webhook-emailer-topic"
}

resource "aws_sns_topic_subscription" "webhook_emailer_topic_subscriber" {
  endpoint  = var.target_email
  protocol  = "email"
  topic_arn = aws_sns_topic.webhook_emailer_topic.arn
}