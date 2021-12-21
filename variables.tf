variable "target_email" {
  type = string
}

data "aws_caller_identity" "current" {}

variable "aws_region" {}
