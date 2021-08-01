resource "aws_ecr_repository" "main" {
  name = "amicleaner"

  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countNumber = 14
          countUnit   = "days"
        }
        action = {
          type = "expire"
        },
      },
    ]
  })
}

resource "aws_iam_user" "github_action" {
  name = "amicleaner"
  path = "/github-actions/"
}

data "aws_iam_policy_document" "github_action" {
  version = "2012-10-17"

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    effect = "Allow"
    resources = [
      aws_ecr_repository.main.arn,
    ]
  }
}

resource "aws_iam_user_policy" "github_action" {
  user   = aws_iam_user.github_action.name
  policy = data.aws_iam_policy_document.github_action.json
}