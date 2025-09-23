resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-cluster-${var.env}"
}

# API GATEWAY
resource "aws_ecs_task_definition" "api_gateway_task_definition" {
  family             = "${var.project_name}-api-gateway-task-def-${var.env}"
  network_mode       = "awsvpc"
  cpu                = "1024"
  memory             = "6144"
  execution_role_arn = aws_iam_role.api_gateway_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-api-gateway-container-${var.env}"
      image     = "${var.api_gateway_ecr_repository_url}:${var.image_tag}"
      essential = true
      command   = ["java", "-jar", "api-gateway.jar"]
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "AUTH_SERVICE_URL"
          value = "http://${aws_service_discovery_service.auth_service_dns_config.name}.${aws_service_discovery_private_dns_namespace.auth_service_dns.name}:8081"
        },
        {
          name  = "USER_SERVICE_URL"
          value = "http://${aws_service_discovery_service.user_service_dns_config.name}.${aws_service_discovery_private_dns_namespace.user_service_dns.name}:8082"
        }
      ]
      secrets = [
        {
          name      = "JWT_SECRET_KEY",
          valueFrom = data.aws_ssm_parameter.jwt_secret_key.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.api_gateway_log_group.name}"
          "awslogs-region"        = "${var.region}"
          "awslogs-stream-prefix" = "ecs"
        }
      },
    }
  ])

  depends_on = [
    aws_service_discovery_service.auth_service_dns_config,
    aws_service_discovery_private_dns_namespace.auth_service_dns,
    aws_service_discovery_service.user_service_dns_config,
    aws_service_discovery_private_dns_namespace.user_service_dns
  ]
}

resource "aws_iam_role" "api_gateway_execution_role" {
  name = "${var.project_name}-api-gateway-task-execution-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
    }]
  })

  tags = {
    Environment = var.env
  }
}

resource "aws_iam_policy" "api_gateway_execution_policy" {
  name = "${var.project_name}-api-gateway-task-execution-policy-${var.env}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["${aws_cloudwatch_log_group.api_gateway_log_group.arn}:*"]
      },
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Effect = "Allow"
        Resource = [
          "${var.api_gateway_ecr_arn}"
        ]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = [
          "${data.aws_ssm_parameter.jwt_secret_key.arn}",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_execution_policy_attachment" {
  role       = aws_iam_role.api_gateway_execution_role.name
  policy_arn = aws_iam_policy.api_gateway_execution_policy.arn
}

resource "aws_security_group" "api_gateway_service_security_group" {
  name   = "${var.project_name}-api-gateway-service-sg-${var.env}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.application_load_balancer_sg_id]
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

resource "aws_ecs_service" "api_gateway_service" {
  name    = "${var.project_name}-api-gateway-service-${var.env}"
  cluster = aws_ecs_cluster.ecs_cluster.id

  task_definition = aws_ecs_task_definition.api_gateway_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.subnet_private_a, var.subnet_private_b]
    security_groups  = [aws_security_group.api_gateway_service_security_group.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.application_load_balancer_tg_arn
    container_name   = "${var.project_name}-api-gateway-container-${var.env}"
    container_port   = 8080
  }

  tags = {
    Environment = var.env
  }
}

resource "aws_appautoscaling_target" "api_gateway_service_scaling_target" {
  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.api_gateway_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_gateway_service_scaling_policy" {
  name               = "${var.project_name}-api-gateway-scaling-policy-${var.env}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_gateway_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_gateway_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_gateway_service_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80.0
    # cooldown per evitare che ecs scali o rimuova task troppo in fretta
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}


# AUTH SERVICE
resource "aws_ecs_task_definition" "auth_service_task_definition" {
  family             = "${var.project_name}-auth-service-task-def-${var.env}"
  network_mode       = "awsvpc"
  cpu                = "1024"
  memory             = "6144"
  execution_role_arn = aws_iam_role.auth_service_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-auth-service-container-${var.env}"
      image     = "${var.auth_service_ecr_repository_url}:${var.image_tag}"
      essential = true
      command   = ["java", "-jar", "auth-service.jar"]
      portMappings = [
        {
          containerPort = 8081
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "JWT_TOKEN_VALIDITY"
          value = "3600000"
        },
        {
          name  = "DATABASE_PORT"
          value = "5432"
        },
        {
          name  = "USER_SERVICE_URL"
          value = "http://${aws_service_discovery_service.user_service_dns_config.name}.${aws_service_discovery_private_dns_namespace.user_service_dns.name}:8082"
        }
      ]
      secrets = [
        {
          name      = "JWT_SECRET_KEY",
          valueFrom = data.aws_ssm_parameter.jwt_secret_key.arn
        },
        {
          name      = "INTERNAL_API_KEY",
          valueFrom = data.aws_ssm_parameter.internal_api_key.arn
        },
        {
          name      = "DATABASE_URL",
          valueFrom = data.aws_ssm_parameter.database_url.arn
        },
        {
          name      = "DATABASE_USERNAME",
          valueFrom = data.aws_ssm_parameter.database_username.arn
        },
        {
          name      = "DATABASE_PASSWORD",
          valueFrom = data.aws_ssm_parameter.database_password.arn
        },
        {
          name      = "DATABASE_NAME",
          valueFrom = data.aws_ssm_parameter.database_name.arn
        },
        {
          name      = "DATABASE_SCHEMA"
          valueFrom = data.aws_ssm_parameter.auth_service_database_schema.arn
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.auth_service_log_group.name}"
          "awslogs-region"        = "${var.region}"
          "awslogs-stream-prefix" = "ecs"
        }
      },
    }
  ])
}

resource "aws_iam_role" "auth_service_execution_role" {
  name = "${var.project_name}-auth-service-task-execution-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
    }]
  })

  tags = {
    Environment = var.env
  }
}

resource "aws_iam_policy" "auth_service_execution_policy" {
  name = "${var.project_name}-auth-service-task-execution-policy-${var.env}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["${aws_cloudwatch_log_group.auth_service_log_group.arn}:*"]
      },
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Effect = "Allow"
        Resource = [
          "${var.auth_service_ecr_arn}"
        ]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = [
          "${data.aws_ssm_parameter.jwt_secret_key.arn}",
          "${data.aws_ssm_parameter.database_url.arn}",
          "${data.aws_ssm_parameter.database_username.arn}",
          "${data.aws_ssm_parameter.database_password.arn}",
          "${data.aws_ssm_parameter.database_name.arn}",
          "${data.aws_ssm_parameter.internal_api_key.arn}",
          "${data.aws_ssm_parameter.auth_service_database_schema.arn}",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "auth_service_execution_policy_attachment" {
  role       = aws_iam_role.auth_service_execution_role.name
  policy_arn = aws_iam_policy.auth_service_execution_policy.arn
}

resource "aws_security_group" "auth_service_security_group" {
  name   = "${var.project_name}-auth-service-sg-${var.env}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.api_gateway_service_security_group.id, var.sqs_handler_sg_id]
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

resource "aws_service_discovery_private_dns_namespace" "auth_service_dns" {
  name = "${var.project_name}-auth-service-dns.local"
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "auth_service_dns_config" {
  name = "${var.project_name}-auth-service-dns-config-${var.env}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.auth_service_dns.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "auth_service" {
  name    = "${var.project_name}-auth-service-${var.env}"
  cluster = aws_ecs_cluster.ecs_cluster.id

  task_definition = aws_ecs_task_definition.auth_service_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [var.subnet_private_a, var.subnet_private_b]
    security_groups = [aws_security_group.auth_service_security_group.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.auth_service_dns_config.arn
  }

  tags = {
    Environment = var.env
  }
}

resource "aws_appautoscaling_target" "auth_service_scaling_target" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.auth_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "auth_service_scaling_policy" {
  name               = "${var.project_name}-auth-service-scaling-policy-${var.env}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.auth_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.auth_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.auth_service_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80.0
    # cooldown per evitare che ecs scali o rimuova task troppo in fretta
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# USER SERVICE
resource "aws_ecs_task_definition" "user_service_task_definition" {
  family             = "${var.project_name}-user-service-task-def-${var.env}"
  network_mode       = "awsvpc"
  cpu                = "1024"
  memory             = "6144"
  execution_role_arn = aws_iam_role.user_service_execution_role.arn
  task_role_arn      = aws_iam_role.user_service_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-user-service-container-${var.env}"
      image     = "${var.user_service_ecr_repository_url}:${var.image_tag}"
      essential = true
      command   = ["java", "-jar", "user-service.jar"]
      portMappings = [
        {
          containerPort = 8082
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "REGION"
          value = "${var.region}"
        },
        {
          name  = "QUEUE_URL"
          value = "${var.queue_url}"
        },
        {
          name  = "JWT_TOKEN_VALIDITY"
          value = "3600000"
        },
        {
          name  = "DATABASE_PORT"
          value = "5432"
        }
      ]
      secrets = [
        {
          name      = "JWT_SECRET_KEY",
          valueFrom = data.aws_ssm_parameter.jwt_secret_key.arn
        },
        {
          name      = "INTERNAL_API_KEY",
          valueFrom = data.aws_ssm_parameter.internal_api_key.arn
        },
        {
          name      = "DATABASE_URL",
          valueFrom = data.aws_ssm_parameter.database_url.arn
        },
        {
          name      = "DATABASE_USERNAME",
          valueFrom = data.aws_ssm_parameter.database_username.arn
        },
        {
          name      = "DATABASE_PASSWORD",
          valueFrom = data.aws_ssm_parameter.database_password.arn
        },
        {
          name      = "DATABASE_NAME",
          valueFrom = data.aws_ssm_parameter.database_name.arn
        },
        {
          name      = "DATABASE_SCHEMA"
          valueFrom = data.aws_ssm_parameter.user_service_database_schema.arn
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.user_service_log_group.name}"
          "awslogs-region"        = "${var.region}"
          "awslogs-stream-prefix" = "ecs"
        }
      },
    }
  ])
}

resource "aws_iam_role" "user_service_execution_role" {
  name = "${var.project_name}-user-task-execution-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
    }]
  })

  tags = {
    Environment = var.env
  }
}

resource "aws_iam_policy" "user_service_execution_policy" {
  name = "${var.project_name}-user-task-execution-policy-${var.env}"


  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["${aws_cloudwatch_log_group.user_service_log_group.arn}:*"]
      },
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Effect = "Allow"
        Resource = [
          "${var.user_service_ecr_arn}"
        ]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = [
          "${data.aws_ssm_parameter.jwt_secret_key.arn}",
          "${data.aws_ssm_parameter.database_url.arn}",
          "${data.aws_ssm_parameter.database_username.arn}",
          "${data.aws_ssm_parameter.database_password.arn}",
          "${data.aws_ssm_parameter.database_name.arn}",
          "${data.aws_ssm_parameter.internal_api_key.arn}",
          "${data.aws_ssm_parameter.user_service_database_schema.arn}"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:DescribeTasks"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          "${aws_iam_role.user_service_task_role.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "user_service_execution_policy_attachment" {
  role       = aws_iam_role.user_service_execution_role.name
  policy_arn = aws_iam_policy.user_service_execution_policy.arn
}

resource "aws_iam_role" "user_service_task_role" {
  name = "${var.project_name}-user-task-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.env
  }
}

resource "aws_iam_policy" "user_service_task_policy" {
  name = "${var.project_name}-user-task-policy-${var.env}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ],
        Resource = "${var.queue_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "user_service_task_policy_attachment" {
  role       = aws_iam_role.user_service_task_role.name
  policy_arn = aws_iam_policy.user_service_task_policy.arn
}

resource "aws_security_group" "user_service_security_group" {
  name   = "${var.project_name}-user-service-sg-${var.env}"
  vpc_id = var.vpc_id

  ingress {
    from_port = 8082
    to_port   = 8082
    protocol  = "tcp"
    security_groups = [
      aws_security_group.api_gateway_service_security_group.id,
      aws_security_group.auth_service_security_group.id
    ]
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

resource "aws_service_discovery_private_dns_namespace" "user_service_dns" {
  name = "${var.project_name}-user-service-dns.local"
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "user_service_dns_config" {
  name = "${var.project_name}-user-service-dns-config-${var.env}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.user_service_dns.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "user_service" {
  name    = "${var.project_name}-user-service-${var.env}"
  cluster = aws_ecs_cluster.ecs_cluster.id

  task_definition = aws_ecs_task_definition.user_service_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [var.subnet_private_a, var.subnet_private_b]
    security_groups = [aws_security_group.user_service_security_group.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.user_service_dns_config.arn
  }

  tags = {
    Environment = var.env
  }
}

resource "aws_appautoscaling_target" "user_service_scaling_target" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.user_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "user_service_scaling_policy" {
  name               = "${var.project_name}-user-service-scaling-policy-${var.env}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.user_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.user_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.user_service_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80.0
    # cooldown per evitare che ecs scali o rimuova task troppo in fretta
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# CLOUDWATCH
resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name              = "/ecs/${var.project_name}/api-gateway-log-group-${var.env}"
  retention_in_days = 7

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "auth_service_log_group" {
  name              = "/ecs/${var.project_name}/auth-service-log-group-${var.env}"
  retention_in_days = 7

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "user_service_log_group" {
  name              = "/ecs/${var.project_name}/user-service-log-group-${var.env}"
  retention_in_days = 7

  tags = {
    Environment = var.env
  }
}

# SSM DATABASE
data "aws_ssm_parameter" "database_url" {
  name            = "/environment/${var.project_name}/database_url"
  with_decryption = true
}
data "aws_ssm_parameter" "database_username" {
  name            = "/environment/${var.project_name}/database_username"
  with_decryption = true
}
data "aws_ssm_parameter" "database_password" {
  name            = "/environment/${var.project_name}/database_password"
  with_decryption = true
}
data "aws_ssm_parameter" "database_name" {
  name            = "/environment/${var.project_name}/database_name"
  with_decryption = true
}
data "aws_ssm_parameter" "auth_service_database_schema" {
  name            = "/environment/${var.project_name}/auth_service_database_schema"
  with_decryption = true
}
data "aws_ssm_parameter" "user_service_database_schema" {
  name            = "/environment/${var.project_name}/user_service_database_schema"
  with_decryption = true
}

# SSM SECURITY
data "aws_ssm_parameter" "jwt_secret_key" {
  name            = "/environment/${var.project_name}/jwt_secret_key"
  with_decryption = true
}
data "aws_ssm_parameter" "internal_api_key" {
  name            = "/environment/${var.project_name}/internal_api_key"
  with_decryption = true
}
