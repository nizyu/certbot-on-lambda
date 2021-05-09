terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "[your backend bucket]"
    key    = "certbot-on-lambda"
  }
}

provider "aws" {}

resource "aws_s3_bucket" "credential-outpt" {
  bucket = "${var.output_bucket_name}"
  acl    = "private"
}

resource "aws_ecr_repository" "certbot-on-lambda" {
  name                 = "certbot-on-lambda"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "certbot-on-lambda" {
  name = "certbot-on-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "certbot-on-lambda" {
  name = "certbot-on-lambda-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:GetChange"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect" : "Allow",
      "Action" : [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource" : [
        "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
      ]
    },
    {
      "Effect":"Allow",
      "Action":[
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource":"arn:aws:s3:::${var.output_bucket_name}/*"
    },
    {
      "Effect":"Allow",
      "Action":[
        "s3:ListBucket"
      ],
      "Resource":"arn:aws:s3:::${var.output_bucket_name}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = "${aws_iam_role.certbot-on-lambda.name}"
  policy_arn = "${aws_iam_policy.certbot-on-lambda.arn}"
}

resource "aws_lambda_function" "certbot-on-lambda" {
  function_name = "certbot_on_lambda"
  role          = "${aws_iam_role.certbot-on-lambda.arn}"

  package_type = "Image"
  image_uri    = "${aws_ecr_repository.certbot-on-lambda.repository_url}:latest"

  timeout = 180

  environment {
    variables = {
      BUCKET = "${var.output_bucket_name}"
      DOMAIN = "${var.route53_domain_name}"
      EMAIL  = "${var.email}"
    }
  }
}

resource "aws_lambda_permission" "certbot-on-lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.certbot-on-lambda.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.certbot-on-lambda.arn}"
}

resource "aws_cloudwatch_event_rule" "certbot-on-lambda" {
  name                = "certbot-on-lambda"
  description         = "certbot-on-lambda"
  schedule_expression = "rate(7 days)"
}

resource "aws_cloudwatch_event_target" "certbot-on-lambda" {
  rule      = "${aws_cloudwatch_event_rule.certbot-on-lambda.name}"
  target_id = "certbot-on-lambda"
  arn       = "${aws_lambda_function.certbot-on-lambda.arn}"
}

