output "api_gateway_ecr_id" {
  value = aws_ecr_repository.api_gateway_ecr.id
}

output "api_gateway_ecr_arn" {
  value = aws_ecr_repository.api_gateway_ecr.arn
}

output "api_gateway_ecr_repository_url" {
  value = aws_ecr_repository.api_gateway_ecr.repository_url
}

output "auth_service_ecr_id" {
  value = aws_ecr_repository.auth_service_ecr.id
}

output "auth_service_ecr_arn" {
  value = aws_ecr_repository.auth_service_ecr.arn
}

output "auth_service_ecr_repository_url" {
  value = aws_ecr_repository.auth_service_ecr.repository_url
}

output "user_service_ecr_id" {
  value = aws_ecr_repository.user_service_ecr.id
}

output "user_service_ecr_arn" {
  value = aws_ecr_repository.user_service_ecr.arn
}

output "user_service_ecr_repository_url" {
  value = aws_ecr_repository.user_service_ecr.repository_url
}