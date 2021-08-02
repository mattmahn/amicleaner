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
            "ec2:DescribeImages",
            "ec2:DescribeInstances",
            "ec2:DescribeSnapshots",
          ]
          Effect   = "Allow"
          Resource = ["*"]
        }
      ]
    })
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]

  tags = {}
}

resource "aws_lambda_function" "amicleaner" {
  function_name = "amicleaner"
  role          = aws_iam_role.amicleaner.arn

  package_type = "Image"
  image_uri    = "${aws_ecr_repository.main.repository_url}:latest"
  image_config {
    command = [
      "amicleaner",
      "--ami-min-days=7",
      "--force-delete",
      "--check-orphans",
      "--mapping-values='Name'",
    ]
  }
  timeout = 300

  tags = {}
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.amicleaner.arn
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

  tags = {}
}
