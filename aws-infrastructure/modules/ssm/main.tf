# SECURITY
resource "aws_ssm_parameter" "jwt_secret_key" {
  name  = "/environment/${var.project_name}/jwt_secret_key"
  type  = "SecureString"
  value = var.jwt_secret_key
}
resource "aws_ssm_parameter" "internal_api_key" {
  name  = "/environment/${var.project_name}/internal_api_key"
  type  = "SecureString"
  value = var.internal_api_key
}

# DATABASE
resource "aws_ssm_parameter" "database_url" {
  // lo creiamo a vuoto in modo che già esista l'arn, verrà poi sovrascritto dal module rds
  name  = "/environment/${var.project_name}/database_url"
  type  = "SecureString"
  value = " "
}
resource "aws_ssm_parameter" "database_username" {
  name  = "/environment/${var.project_name}/database_username"
  type  = "SecureString"
  value = var.database_username
}
resource "aws_ssm_parameter" "database_password" {
  name  = "/environment/${var.project_name}/database_password"
  type  = "SecureString"
  value = var.database_password
}
resource "aws_ssm_parameter" "database_name" {
  name  = "/environment/${var.project_name}/database_name"
  type  = "SecureString"
  value = "${var.database_name}_${var.env}"
}
resource "aws_ssm_parameter" "auth_service_database_schema" {
  name  = "/environment/${var.project_name}/auth_service_database_schema"
  type  = "SecureString"
  value = var.auth_service_database_schema
}
resource "aws_ssm_parameter" "user_service_database_schema" {
  name  = "/environment/${var.project_name}/user_service_database_schema"
  type  = "SecureString"
  value = var.user_service_database_schema
}
