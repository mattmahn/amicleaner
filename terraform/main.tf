resource "aws_ecr_repository" "main" {
  name = "amicleaner"

  encryption_configuration {
    encryption_type = "KMS"
  }
}

aws "aws_ecr_lifecycle_policy" "main" {
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