variable "env" {
  type = string
}
variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_public_a" {
  type = string
}
variable "subnet_public_b" {
  type = string
}
variable "subnet_private_a" {
  type = string
}
variable "subnet_private_b" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "api_gateway_ecr_repository_url" {
  type = string
}

variable "api_gateway_ecr_arn" {
  type = string
}

variable "auth_service_ecr_repository_url" {
  type = string
}

variable "auth_service_ecr_arn" {
  type = string
}

variable "user_service_ecr_repository_url" {
  type = string
}

variable "user_service_ecr_arn" {
  type = string
}

variable "application_load_balancer_sg_id" {
  type = string
}

variable "application_load_balancer_tg_arn" {
  type = string
}

variable "queue_arn" {
  type = string
}

variable "queue_url" {
  type = string
}

variable "sqs_handler_sg_id" {
  type = string
}