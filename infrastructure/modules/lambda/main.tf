# SQS LAMBDA CONSUMER
resource "aws_lambda_function" "sqs_handler" {
  function_name = "${var.project_name}-lambda-sqs-${var.env}"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 15

  vpc_config {
    subnet_ids         = [var.subnet_private_a, var.subnet_private_b]
    security_group_ids = [aws_security_group.sqs_handler_sg.id]
  }

  environment {
    variables = {
      "AUTH_SERVICE_URL"      = "${var.auth_service_url}",
      "INTERNAL_API_KEY_NAME" = "/environment/${var.project_name}/internal_api_key"
    }
  }

  filename         = "${path.module}/sqs-handler.zip" # il pacchetto deve essere creato prima
  source_code_hash = filebase64sha256("${path.module}/sqs-handler.zip")
}

resource "aws_security_group" "sqs_handler_sg" {
  name   = "${var.project_name}-lambda-sqs-sg-${var.env}"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-execution-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_execution_policy" {
  name = "${var.project_name}-lambda-execution-policy-${var.env}"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["${aws_cloudwatch_log_group.lambda_sqs_log_group.arn}:*"]
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = [
          "${var.internal_api_key_arn}",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          "${var.queue_arn}"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "lambda_sqs_trigger" {
  event_source_arn = var.queue_arn
  function_name    = aws_lambda_function.sqs_handler.arn
  batch_size       = 1 // viene invocata un'esecuzione per ogni messaggio
  enabled          = true
}

resource "aws_lambda_permission" "allow_sqs_invoke" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs_handler.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = var.queue_arn
}

resource "aws_cloudwatch_log_group" "lambda_sqs_log_group" {
  name              = "/aws/lambda/${var.project_name}-lambda-sqs-${var.env}"
  retention_in_days = 7

  tags = {
    Environment = var.env
  }
}
