output "lambda_execution_role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}

output "sqs_handler_sg_id" {
  value = aws_security_group.sqs_handler_sg.id
}
