terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 1.1.0"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "webhook-emailer"
  length = 4
}

resource "aws_s3_bucket" "webhook_emailer_lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  acl           = "private"
  force_destroy = true
}

data "archive_file" "webhook_emailer_handler" {
  type = "zip"

  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/webook-email-handler.zip"
}

resource "aws_s3_bucket_object" "webhook_emailer_handler_lambda" {
  bucket = aws_s3_bucket.webhook_emailer_lambda_bucket.id
  key    = "webook-email-handler.zip"
  source = data.archive_file.webhook_emailer_handler.output_path

  etag = filemd5(data.archive_file.webhook_emailer_handler.output_path)
}

resource "random_id" "webhook_emailer_handler_param_secret" {
  byte_length = 10
}


output "webhook_emailer_handler_param_secret" {
  value = random_id.webhook_emailer_handler_param_secret.b64_url
}