variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc" {
  type = string
}

variable "database_retention" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_instance_class" {
  type = string
}

variable "database_identifier" {
  type = string
}

variable "subnet_private_a" {
  type = string
}

variable "subnet_private_b" {
  type = string
}

variable "bastion_host_security_group_id" {
  type = string
}

variable "auth_service_security_group_id" {
  type = string
}

variable "user_service_security_group_id" {
  type = string
}

