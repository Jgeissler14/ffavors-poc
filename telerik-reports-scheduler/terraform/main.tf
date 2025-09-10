# Telerik Reports Scheduler with SQS Queue - Terraform Configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}
data "aws_ssm_parameter" "db_connection" {
  name = var.db_connection_ssm_parameter_name
}

# S3 Bucket for Reports
resource "aws_s3_bucket" "reports_bucket" {
  bucket = "${var.reports_bucket_name}-${var.environment}"

  tags = {
    Name        = "Telerik Reports Bucket"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

resource "aws_s3_bucket_versioning" "reports_bucket_versioning" {
  bucket = aws_s3_bucket.reports_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports_bucket_encryption" {
  bucket = aws_s3_bucket.reports_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "reports_bucket_lifecycle" {
  bucket = aws_s3_bucket.reports_bucket.id

  rule {
    id     = "delete_old_reports"
    status = "Enabled"

    filter {
      prefix = "reports/"
    }

    expiration {
      days = var.s3_lifecycle_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_ecr_repository" "telerik_report_generator_ecr" {
  name                 = "telerik-report-generator-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "Telerik Report Generator ECR"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "telerik-reports-scheduler-lambda-sg-${var.environment}"
  description = "Security group for the Telerik Reports Scheduler Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Telerik Reports Lambda SG"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# SQS Queue for Report Processing
resource "aws_sqs_queue" "report_queue" {
  name                       = "telerik-reports-queue-${var.environment}"
  visibility_timeout_seconds = var.lambda_timeout + 30
  message_retention_seconds  = 1209600 # 14 days
  max_message_size          = 262144  # 256 KB
  delay_seconds             = 0
  receive_wait_time_seconds = 20 # Long polling

  # Redrive policy for failed messages
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.report_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "Telerik Reports Queue"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# Dead Letter Queue for failed messages
resource "aws_sqs_queue" "report_dlq" {
  name                      = "telerik-reports-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "Telerik Reports Dead Letter Queue"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

resource "aws_vpc_endpoint" "sqs_vpc_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = ["${data.aws_subnets.default.ids[0]}"]
  security_group_ids = [aws_security_group.lambda_sg.id]

  tags = {
    Name        = "Telerik Reports SQS VPC Endpoint"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name = "telerik-reports-scheduler-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Telerik Reports Lambda Role"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# IAM Policy for Lambda Functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "telerik-reports-scheduler-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

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
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.reports_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.reports_bucket.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ses:FromAddress" = var.from_email
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.report_queue.arn,
          aws_sqs_queue.report_dlq.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ssm:GetParameter"],
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.db_connection_ssm_parameter_name}"
      },
      {
        Effect = "Allow",
        Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"],
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "polling_logs" {
  name              = "/aws/lambda/telerik-reports-polling-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "Telerik Reports Polling Logs"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

resource "aws_cloudwatch_log_group" "generator_logs" {
  name              = "/aws/lambda/telerik-reports-generator-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "Telerik Reports Generator Logs"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# Build Lambda packages
resource "null_resource" "build_polling" {
  triggers = {
    code_hash = filebase64sha256("../src/ReportScheduler/PollingFunction.cs")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ../src/ReportScheduler
      dotnet publish -c Release -r linux-x64 --self-contained false
    EOT
  }
}

# Package Lambda functions
data "archive_file" "polling_zip" {
  type        = "zip"
  source_dir  = "../src/ReportScheduler/bin/Release/net8.0/linux-x64/publish"
  output_path = "../polling-deployment.zip"
  depends_on  = [null_resource.build_polling]
}

# Polling Lambda Function (runs daily at 8 AM)
resource "aws_lambda_function" "report_polling" {
  filename         = data.archive_file.polling_zip.output_path
  function_name    = "telerik-reports-polling-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "ReportScheduler::ReportScheduler.PollingFunction::FunctionHandler"
  source_code_hash = data.archive_file.polling_zip.output_base64sha256
  runtime         = "dotnet8"
  timeout         = 60
  memory_size     = 512

  vpc_config {
    subnet_ids         = ["${data.aws_subnets.default.ids[0]}"]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      REPORT_QUEUE_URL = aws_sqs_queue.report_queue.url
      ENVIRONMENT      = var.environment
      DB_CONNECTION      = data.aws_ssm_parameter.db_connection.value
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.polling_logs,
  ]

  tags = {
    Name        = "Telerik Reports Polling"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# Report Generator Lambda Function (triggered by SQS)
resource "aws_lambda_function" "report_generator" {
  function_name    = "telerik-reports-generator-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  package_type     = "Image"
  image_uri        = "${aws_ecr_repository.telerik_report_generator_ecr.repository_url}:latest"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  vpc_config {
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      REPORTS_BUCKET_NAME = aws_s3_bucket.reports_bucket.bucket
      REPORTS_BUCKET     = aws_s3_bucket.reports_bucket.bucket
      FROM_EMAIL         = var.from_email
      ENVIRONMENT        = var.environment
      DB_CONNECTION      = data.aws_ssm_parameter.db_connection.value
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.generator_logs,
    aws_ecr_repository.telerik_report_generator_ecr # Add dependency on ECR repo
  ]

  tags = {
    Name        = "Telerik Reports Generator"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# SQS Event Source Mapping for Generator Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.report_queue.arn
  function_name    = aws_lambda_function.report_generator.arn
  batch_size       = 1

  # Configure scaling
  scaling_config {
    maximum_concurrency = var.max_concurrent_executions
  }
}

# EventBridge Rule - runs daily at 8 AM UTC
resource "aws_cloudwatch_event_rule" "daily_polling" {
  name                = "telerik-reports-daily-polling-${var.environment}"
  description         = "Triggers report polling daily at 8 AM UTC"
  schedule_expression = var.polling_schedule

  tags = {
    Name        = "Daily Report Polling"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "polling_target" {
  rule      = aws_cloudwatch_event_rule.daily_polling.name
  target_id = "PollingTarget"
  arn       = aws_lambda_function.report_polling.arn
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_polling_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_polling.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_polling.arn
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "polling_errors" {
  alarm_name          = "telerik-reports-polling-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors polling lambda errors"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.report_polling.function_name
  }

  tags = {
    Name        = "Polling Error Alarm"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

resource "aws_cloudwatch_metric_alarm" "generator_errors" {
  alarm_name          = "telerik-reports-generator-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors generator lambda errors"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.report_generator.function_name
  }

  tags = {
    Name        = "Generator Error Alarm"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name          = "telerik-reports-queue-depth-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors SQS queue depth"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    QueueName = aws_sqs_queue.report_queue.name
  }

  tags = {
    Name        = "Queue Depth Alarm"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "telerik-reports-dlq-messages-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors dead letter queue messages"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    QueueName = aws_sqs_queue.report_dlq.name
  }

  tags = {
    Name        = "Dead Letter Queue Alarm"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

# SNS Topic for Alerts (optional)
resource "aws_sns_topic" "alerts" {
  count = var.alarm_email != "" ? 1 : 0
  name  = "telerik-reports-scheduler-alerts-${var.environment}"

  tags = {
    Name        = "Telerik Reports Alerts"
    Environment = var.environment
    Project     = "TelerikReportsScheduler"
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# FFavors API ECR Repository
resource "aws_ecr_repository" "ffavorsapi_ecr" {
  name                 = "ffavorsapi-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "FFavors API ECR"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# FFavors API ECS Cluster
resource "aws_ecs_cluster" "ffavorsapi_cluster" {
  name = "ffavorsapi-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "FFavors API Cluster"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# Security Group for the Application Load Balancer
resource "aws_security_group" "ffavorsapi_alb" {
  name        = "ffavorsapi-alb-sg-${var.environment}"
  description = "Allow HTTP traffic to FFavors API ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "FFavors API ALB SG"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# Security Group for the ECS Tasks
resource "aws_security_group" "ffavorsapi_ecs_tasks" {
  name        = "ffavorsapi-ecs-tasks-sg-${var.environment}"
  description = "Allow traffic from the ALB to the ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.ffavorsapi_alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "FFavors API ECS Tasks SG"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

data "aws_subnet" "all_subnets" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

locals {
  subnets_by_az = {
    for id, subnet in data.aws_subnet.all_subnets : subnet.availability_zone => id...
  }
  unique_subnets = [for ids in values(local.subnets_by_az) : ids[0]]
}

# Application Load Balancer
resource "aws_lb" "ffavorsapi_alb" {
  name               = "ffavorsapi-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ffavorsapi_alb.id]
  subnets            = local.unique_subnets

  tags = {
    Name        = "FFavors API ALB"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# Target Group for the ALB
resource "aws_lb_target_group" "ffavorsapi_tg" {
  name        = "ffavorsapi-tg-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/swagger/index.html"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "FFavors API Target Group"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# Listener for the ALB
resource "aws_lb_listener" "ffavorsapi_listener" {
  load_balancer_arn = aws_lb.ffavorsapi_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ffavorsapi_tg.arn
  }

  tags = {
    Name        = "FFavors API ALB Listener"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ffavorsapi_ecs_execution_role" {
  name = "ffavorsapi-ecs-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "FFavors API ECS Execution Role"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

resource "aws_iam_role_policy_attachment" "ffavorsapi_ecs_execution_role_policy" {
  role       = aws_iam_role.ffavorsapi_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "ffavorsapi_ecs_task_role" {
  name = "ffavorsapi-ecs-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "FFavors API ECS Task Role"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# CloudWatch Log Group for the ECS Service
resource "aws_cloudwatch_log_group" "ffavorsapi_logs" {
  name              = "/ecs/ffavorsapi-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "FFavors API Logs"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "ffavorsapi_task" {
  family                   = "ffavorsapi-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ffavorsapi_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ffavorsapi_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "ffavorsapi"
      image     = "${aws_ecr_repository.ffavorsapi_ecr.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ffavorsapi_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Development"
        },
        {
          name  = "ASPNETCORE_URLS"
          value = "http://+:8080"
        }
      ]
    }
  ])

  tags = {
    Name        = "FFavors API Task Definition"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}

# ECS Service
resource "aws_ecs_service" "ffavorsapi_service" {
  name            = "ffavorsapi-service-${var.environment}"
  cluster         = aws_ecs_cluster.ffavorsapi_cluster.id
  task_definition = aws_ecs_task_definition.ffavorsapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.unique_subnets
    security_groups = [aws_security_group.ffavorsapi_ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ffavorsapi_tg.arn
    container_name   = "ffavorsapi"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.ffavorsapi_listener]

  tags = {
    Name        = "FFavors API ECS Service"
    Environment = var.environment
    Project     = "FFavorsAPI"
  }
}