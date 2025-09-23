# SQS QUEUE
resource "aws_sqs_queue" "queue" {
  name = "${var.project_name}-queue-${var.env}"

  visibility_timeout_seconds  = 15 // tempo per cui il messaggio rimane invisibile da quando è stato recuperato da un consumer
  delay_seconds               = 0  // delay di visibilità del messaggio sulla coda
  max_message_size            = 2048
  message_retention_seconds   = 86400 // un giorno HA SENSO???
  fifo_queue                  = false
  content_based_deduplication = false

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5 # dopo 5 tentativi falliti, il messaggio va nella DLQ
  })

  tags = {
    Environment = var.env
  }
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                      = "${var.project_name}-dlq-${var.env}"
  message_retention_seconds = 604800 # 7 giorni

  tags = {
    Environment = var.env
  }
}

data "aws_iam_policy_document" "queue_policy_documment" {
  statement {
    sid    = "AllowAuthServiceToSendMessage"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        var.user_service_execution_role_arn
      ]
    }

    actions = [
      "sqs:SendMessage",
    ]

    resources = [aws_sqs_queue.queue.arn]
  }

  statement {
    sid    = "AllowLambdaConsumerToProcessMessage"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        var.lambda_execution_role_arn
      ]
    }

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
    ]

    resources = [aws_sqs_queue.queue.arn]
  }
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.queue_policy_documment.json
}
