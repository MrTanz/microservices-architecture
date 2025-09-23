module "vpc_block" {
  source = "./modules/vpc"

  # ENV
  env          = var.env
  region       = var.region
  project_name = var.project_name
}

module "ecr_block" {
  source = "./modules/ecr"

  # ENV
  env = var.env
}

module "lambda_block" {
  source = "./modules/lambda"

  # ENV
  env          = var.env
  project_name = var.project_name

  # SQS
  queue_arn = module.sqs_block.queue_arn

  # ECS
  auth_service_url = module.ecs_block.auth_service_url

  # SSM
  internal_api_key_arn = module.ssm_module.internal_api_key_arn

  # VPC
  vpc_id           = module.vpc_block.vpc_id
  subnet_private_a = module.vpc_block.private_subnet_a_id
  subnet_private_b = module.vpc_block.private_subnet_b_id
}

module "sqs_block" {
  source = "./modules/sqs"

  # ENV
  env          = var.env
  project_name = var.project_name
  region       = var.region

  # ECS
  user_service_execution_role_arn = module.ecs_block.user_service_execution_role_arn

  # LAMBDA
  lambda_execution_role_arn = module.lambda_block.lambda_execution_role_arn
}

module "ecs_block" {
  source = "./modules/ecs"

  # ENV
  env          = var.env
  region       = var.region
  image_tag    = var.image_tag
  project_name = var.project_name

  # LAMBDA
  sqs_handler_sg_id = module.lambda_block.sqs_handler_sg_id

  # SQS
  queue_arn = module.sqs_block.queue_arn
  queue_url = module.sqs_block.queue_url

  # VPC
  vpc_id           = module.vpc_block.vpc_id
  subnet_public_a  = module.vpc_block.public_subnet_a_id
  subnet_public_b  = module.vpc_block.public_subnet_b_id
  subnet_private_a = module.vpc_block.private_subnet_a_id
  subnet_private_b = module.vpc_block.private_subnet_b_id

  # ECR
  api_gateway_ecr_arn            = module.ecr_block.api_gateway_ecr_arn
  api_gateway_ecr_repository_url = module.ecr_block.api_gateway_ecr_repository_url

  auth_service_ecr_arn            = module.ecr_block.auth_service_ecr_arn
  auth_service_ecr_repository_url = module.ecr_block.auth_service_ecr_repository_url

  user_service_ecr_arn            = module.ecr_block.user_service_ecr_arn
  user_service_ecr_repository_url = module.ecr_block.user_service_ecr_repository_url

  # EC2
  application_load_balancer_sg_id  = module.ec2_block.application_load_balancer_sg_id
  application_load_balancer_tg_arn = module.ec2_block.application_load_balancer_tg_arn

  depends_on = [module.ssm_module]
}

module "ec2_block" {
  source = "./modules/ec2"

  # ENV
  env                         = var.env
  bastion_host_instance_class = var.bastion_host_instance_class
  project_name                = var.project_name

  # VPC
  vpc_id             = module.vpc_block.vpc_id
  public_subnet_a_id = module.vpc_block.public_subnet_a_id
  public_subnet_b_id = module.vpc_block.public_subnet_b_id
}

module "rds_module" {
  source = "./modules/rds"

  # ENV
  env                     = var.env
  database_identifier     = var.database_identifier
  database_instance_class = var.database_instance_class
  database_retention      = var.database_retention
  database_name           = var.database_name
  project_name            = var.project_name

  # VPC
  vpc              = module.vpc_block.vpc_id
  subnet_private_a = module.vpc_block.private_subnet_a_id
  subnet_private_b = module.vpc_block.private_subnet_b_id

  # EC2
  bastion_host_security_group_id = module.ec2_block.bastion_host_security_group_id

  # ECS
  auth_service_security_group_id = module.ecs_block.auth_service_security_group_id
  user_service_security_group_id = module.ecs_block.user_service_security_group_id
  
  depends_on = [ module.ssm_module ]
}

module "ssm_module" {
  source = "./modules/ssm"

  # ENV
  env          = var.env
  project_name = var.project_name

  database_name                = var.database_name
  database_password            = var.database_password
  database_username            = var.database_username
  auth_service_database_schema = var.auth_service_database_schema
  user_service_database_schema = var.user_service_database_schema

  jwt_secret_key   = var.jwt_secret_key
  internal_api_key = var.internal_api_key
}
