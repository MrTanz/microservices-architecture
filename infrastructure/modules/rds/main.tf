# Database RDS PostgreSQL
resource "aws_db_instance" "database_instance" {
  allocated_storage       = 100
  instance_class          = var.database_instance_class
  engine                  = "postgres"
  username                = data.aws_ssm_parameter.database_username.value
  password                = data.aws_ssm_parameter.database_password.value
  vpc_security_group_ids  = [aws_security_group.database_instance_security_group.id]
  db_subnet_group_name    = aws_db_subnet_group.database_instance_subnet_group.name
  db_name                 = "${var.database_name}_${var.env}"
  identifier              = "${var.database_identifier}-${var.env}"
  storage_encrypted       = true
  kms_key_id              = data.aws_kms_alias.database_instance_kms_key.arn
  publicly_accessible     = false
  skip_final_snapshot     = true
  parameter_group_name    = aws_db_parameter_group.database_instance_parameter_group.name
  apply_immediately       = true
  storage_type            = var.env == "prod" ? "io1" : "gp2"
  iops                    = var.env == "prod" ? 3000 : 0
  deletion_protection     = var.env == "prod"
  backup_retention_period = var.database_retention

  tags = {
    Name        = "${var.project_name}-database-${var.env}"
    Environment = var.env
  }
}

# Parameter group per RDS Database
resource "aws_db_parameter_group" "database_instance_parameter_group" {
  name   = "${var.project_name}-db-parameter-group-${var.env}"
  family = "postgres17"

  parameter {
    name  = "rds.force_ssl"
    value = false
  }
  tags = {
    Environment = var.env
  }
}

# Security Group per RDS Database
resource "aws_security_group" "database_instance_security_group" {
  name   = "${var.project_name}-database-sg-${var.env}"
  vpc_id = var.vpc

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.bastion_host_security_group_id, var.auth_service_security_group_id, var.user_service_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.env
  }
}

# Subnet group per RDS Database
resource "aws_db_subnet_group" "database_instance_subnet_group" {
  name       = "${var.project_name}-db-subnet-group-${var.env}"
  subnet_ids = [var.subnet_private_a, var.subnet_private_b]

  tags = {
    Environment = var.env
  }
}

# Recupero KMS Key
data "aws_kms_alias" "database_instance_kms_key" {
  name = "alias/aws/rds"
}

# SSM DATABASE
data "aws_ssm_parameter" "database_username" {
  name            = "/environment/${var.project_name}/database_username"
  with_decryption = true
}
data "aws_ssm_parameter" "database_password" {
  name            = "/environment/${var.project_name}/database_password"
  with_decryption = true
}
resource "aws_ssm_parameter" "database_url" {
  name      = "/environment/${var.project_name}/database_url"
  type      = "SecureString"
  value     = aws_db_instance.database_instance.address
  overwrite = true
}
