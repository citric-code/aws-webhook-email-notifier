resource "aws_api_gateway_rest_api" "webhook-emailer-api" {
  name = "webhook-emailer-api"
}


resource "aws_api_gateway_resource" "webhook-emailer-api-resource" {
  parent_id   = aws_api_gateway_rest_api.webhook-emailer-api.root_resource_id
  path_part   = "emailer"
  rest_api_id = aws_api_gateway_rest_api.webhook-emailer-api.id
}

resource "aws_api_gateway_method" "webhook-emailer-api-get-method" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.webhook-emailer-api-resource.id
  rest_api_id   = aws_api_gateway_rest_api.webhook-emailer-api.id
}

resource "aws_api_gateway_integration" "webhook-emailer-lambda-integration" {
 rest_api_id             = aws_api_gateway_rest_api.webhook-emailer-api.id
  resource_id             = aws_api_gateway_resource.webhook-emailer-api-resource.id
  http_method             = aws_api_gateway_method.webhook-emailer-api-get-method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook_emailer_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "prod-deployment" {
  rest_api_id = aws_api_gateway_rest_api.webhook-emailer-api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook-emailer-api-resource.id,
      aws_api_gateway_method.webhook-emailer-api-get-method.id,
      aws_api_gateway_integration.webhook-emailer-lambda-integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod-stage" {
  deployment_id = aws_api_gateway_deployment.prod-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.webhook-emailer-api.id
  stage_name    = "prod"
}

