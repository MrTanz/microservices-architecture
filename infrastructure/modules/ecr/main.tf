# creiamo un Amazon Elastic Container Registry per poter versionare e gestire le immagini
resource "aws_ecr_repository" "api_gateway_ecr" {
  name = "api-gateway-ecr-${var.env}"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "auth_service_ecr" {
  name = "auth-service-ecr-${var.env}"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "user_service_ecr" {
  name = "user-service-ecr-${var.env}"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "api_gateway_ecr_policy" {
  repository = aws_ecr_repository.api_gateway_ecr.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowPushPull",
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy"
        ],
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "auth_service_ecr_policy" {
  repository = aws_ecr_repository.auth_service_ecr.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowPushPull",
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy"
        ],
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "user_service_ecr_policy" {
  repository = aws_ecr_repository.user_service_ecr.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowPushPull",
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy"
        ],
      }
    ]
  })
}
