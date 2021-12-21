resource "aws_lambda_function" "webhook_emailer_lambda" {
  function_name = "webhook_email_handler"

  s3_bucket = aws_s3_bucket.webhook_emailer_lambda_bucket.id
  s3_key    = aws_s3_bucket_object.webhook_emailer_handler_lambda.key

  runtime = "python3.9"
  handler = "webook_email_handler.handle"

  source_code_hash = data.archive_file.webhook_emailer_handler.output_base64sha256

  role = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      "TOPIC_ARN" = aws_sns_topic.webhook_emailer_topic.arn,
      "PARAM_SECRET" = random_id.webhook_emailer_handler_param_secret.b64_url,
    }
  }
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.webhook_emailer_lambda.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "webhook-emailer-lambda-handler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}

resource "aws_iam_role_policy" "sns_publish" {
  name = "webhook-emailer-sns-publish-role"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    "Statement": [
      {
        "Action": [
          "SNS:Publish",
        ],
        "Effect": "Allow",
        "Resource": aws_sns_topic.webhook_emailer_topic.arn,
      }
    ]
  })
}

resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook_emailer_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.webhook-emailer-api.id}/*/${aws_api_gateway_method.webhook-emailer-api-get-method.http_method}${aws_api_gateway_resource.webhook-emailer-api-resource.path}"
}