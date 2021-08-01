data "aws_region" "current" {}

data "aws_iam_policy_document" "amicleaner" {
  version = "2012-10-17"
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "amicleaner" {
  name = "amicleaner"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["sts:AssumeRole"]
        Principal = { Service = "lambda.amazonaws.com" }
        Effect    = "Allow"
      }
    ]
  })
  inline_policy {
    name = "stuff"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeLaunchConfigurations",
            "ec2:DeleteSnapshot",
            "ec2:DeregisterImage",
            "ec2:DescribeImage",
            "ec2:DescribeInstance",
            "ec2:DescribeSnapshots",
          ]
          Effect   = "Allow"
          Resource = ["*"]
        }
      ]
    })
  }
}

resource "aws_lambda_function" "amicleaner" {
  function_name = "amicleaner"
  role          = aws_iam_role.amicleaner.arn

  image_uri = "753998182346.dkr.ecr.us-east-2.amazonaws.com/amicleaner:latest"
  image_config {
    command = "amicleaner --ami-min-days 7 --force-delete --check-orphans --mapping-values 'Name'"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.amicleaner.name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly.arn
}

resource "aws_cloudwatch_event_target" "weekly" {
  arn  = aws_lambda_function.amicleaner.arn
  rule = aws_cloudwatch_event_rule.weekly.id
}

resource "aws_cloudwatch_event_rule" "weekly" {
  name                = "amicleaner-weekly"
  description         = "Run amicleaner weekly"
  is_enabled          = true
  schedule_expression = "rate(7 days)"
}
