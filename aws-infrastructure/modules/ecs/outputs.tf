output "api_gateway_security_group_id" {
  value = aws_security_group.api_gateway_service_security_group.id
}

output "auth_service_security_group_id" {
  value = aws_security_group.auth_service_security_group.id
}

output "user_service_security_group_id" {
  value = aws_security_group.user_service_security_group.id
}

output "auth_service_url" {
  value = "http://${aws_service_discovery_service.auth_service_dns_config.name}.${aws_service_discovery_private_dns_namespace.auth_service_dns.name}:8081"
}

output "api_gateway_execution_role_arn" {
  value = aws_iam_role.api_gateway_execution_role.arn
}

output "auth_service_execution_role_arn" {
  value = aws_iam_role.auth_service_execution_role.arn
}

output "user_service_execution_role_arn" {
  value = aws_iam_role.user_service_execution_role.arn
}