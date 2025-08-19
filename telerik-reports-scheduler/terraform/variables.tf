# SQS-Based Telerik Reports Scheduler - Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "from_email" {
  description = "Email address for sending reports (must be verified in SES)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.from_email))
    error_message = "Please provide a valid email address."
  }
}

variable "reports_bucket_name" {
  description = "Base name for the S3 bucket (environment will be appended)"
  type        = string
  default     = "telerik-reports-poc-bucket"
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarms (optional)"
  type        = string
  default     = ""
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds for report generation"
  type        = number
  default     = 300
  
  validation {
    condition     = var.lambda_timeout >= 30 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 30 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB for report generation"
  type        = number
  default     = 1024
  
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 128 and 10240 MB."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "s3_lifecycle_days" {
  description = "Number of days to keep reports in S3"
  type        = number
  default     = 90
  
  validation {
    condition     = var.s3_lifecycle_days >= 1
    error_message = "S3 lifecycle days must be at least 1."
  }
}

variable "polling_schedule" {
  description = "EventBridge schedule expression for polling (when to check for reports to run)"
  type        = string
  default     = "cron(0 8 * * ? *)" # 8 AM UTC daily
  
  validation {
    condition     = can(regex("^(rate\\(|cron\\()", var.polling_schedule))
    error_message = "Polling schedule must be a valid EventBridge schedule expression."
  }
}

variable "sqs_batch_size" {
  description = "Number of SQS messages to process in a single Lambda invocation"
  type        = number
  default     = 5
  
  validation {
    condition     = var.sqs_batch_size >= 1 && var.sqs_batch_size <= 10
    error_message = "SQS batch size must be between 1 and 10."
  }
}

variable "max_concurrent_executions" {
  description = "Maximum number of concurrent Lambda executions for SQS processing"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_concurrent_executions >= 1 && var.max_concurrent_executions <= 1000
    error_message = "Max concurrent executions must be between 1 and 1000."
  }
}

variable "vpc_id" {
  description = "VPC ID to deploy the lambda functions into"
  type        = string
  default     = "vpc-0c6b7e34ce137c4b7"
}

variable "db_connection_ssm_parameter_name" {
  description = "The name of the SSM parameter that contains the database connection string"
  type        = string
  default     = "/ffavors/connection-string"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
