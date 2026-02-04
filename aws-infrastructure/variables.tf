variable "region" {
  type = string
}
variable "project_name" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "bastion_host_instance_class" {
  type = string
}

variable "env" {
  type = string
}

variable "database_instance_class" {
  type = string
}

variable "database_identifier" {
  type = string
}

variable "database_retention" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_username" {
  type = string
}

variable "database_password" {
  type = string
}

variable "jwt_secret_key" {
  type = string
}
variable "internal_api_key" {
  type = string
}
variable "auth_service_database_schema" {
  type = string
}
variable "user_service_database_schema" {
  type = string
}

