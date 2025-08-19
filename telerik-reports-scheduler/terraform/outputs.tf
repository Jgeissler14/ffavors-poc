# SQS-Based Telerik Reports Scheduler - Outputs

output "polling_lambda_function_arn" {
  description = "ARN of the polling Lambda function"
  value       = aws_lambda_function.report_polling.arn
}

output "polling_lambda_function_name" {
  description = "Name of the polling Lambda function"
  value       = aws_lambda_function.report_polling.function_name
}

output "generator_lambda_function_arn" {
  description = "ARN of the generator Lambda function"
  value       = aws_lambda_function.report_generator.arn
}

output "generator_lambda_function_name" {
  description = "Name of the generator Lambda function"
  value       = aws_lambda_function.report_generator.function_name
}

output "sqs_queue_url" {
  description = "URL of the SQS queue for report processing"
  value       = aws_sqs_queue.report_queue.url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue for report processing"
  value       = aws_sqs_queue.report_queue.arn
}

output "sqs_dlq_url" {
  description = "URL of the SQS dead letter queue"
  value       = aws_sqs_queue.report_dlq.url
}

output "sqs_dlq_arn" {
  description = "ARN of the SQS dead letter queue"
  value       = aws_sqs_queue.report_dlq.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for reports"
  value       = aws_s3_bucket.reports_bucket.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for reports"
  value       = aws_s3_bucket.reports_bucket.arn
}

output "polling_cloudwatch_log_group" {
  description = "CloudWatch log group for polling Lambda function"
  value       = aws_cloudwatch_log_group.polling_logs.name
}

output "generator_cloudwatch_log_group" {
  description = "CloudWatch log group for generator Lambda function"
  value       = aws_cloudwatch_log_group.generator_logs.name
}

output "eventbridge_rule_name" {
  description = "EventBridge rule for daily polling"
  value       = aws_cloudwatch_event_rule.daily_polling.name
}

output "from_email" {
  description = "Email address used for sending reports"
  value       = var.from_email
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts (if configured)"
  value       = var.alarm_email != "" ? aws_sns_topic.alerts[0].arn : null
}

output "polling_schedule" {
  description = "EventBridge schedule for polling"
  value       = var.polling_schedule
}

# Useful commands for monitoring and testing
output "useful_commands" {
  description = "Useful AWS CLI commands for monitoring and testing"
  value = {
    test_polling = "aws lambda invoke --function-name ${aws_lambda_function.report_polling.function_name} --payload '{}' response.json && cat response.json"
    
    view_polling_logs = "aws logs filter-log-events --log-group-name ${aws_cloudwatch_log_group.polling_logs.name} --start-time $(date -d '1 hour ago' +%s)000"
    
    view_generator_logs = "aws logs filter-log-events --log-group-name ${aws_cloudwatch_log_group.generator_logs.name} --start-time $(date -d '1 hour ago' +%s)000"
    
    check_queue_depth = "aws sqs get-queue-attributes --queue-url ${aws_sqs_queue.report_queue.url} --attribute-names ApproximateNumberOfMessages"
    
    check_dlq_messages = "aws sqs get-queue-attributes --queue-url ${aws_sqs_queue.report_dlq.url} --attribute-names ApproximateNumberOfMessages"
    
    list_reports = "aws s3 ls s3://${aws_s3_bucket.reports_bucket.bucket}/reports/ --recursive --human-readable"
    
    send_test_message = "aws sqs send-message --queue-url ${aws_sqs_queue.report_queue.url} --message-body '{\"ReportId\":\"test-report\",\"ReportName\":\"Manual Test Report\",\"ReportType\":\"TestReport\",\"Recipients\":[\"${var.from_email}\"],\"Parameters\":{},\"QueuedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"Priority\":1}'"
  }
}

# Architecture summary
output "architecture_summary" {
  description = "Summary of the deployed architecture"
  value = {
    description = "SQS-based Telerik Reports Scheduler with decoupled processing"
    components = {
      polling_lambda = "Checks schedules and queues reports (daily at 8 AM UTC)"
      sqs_queue = "Decouples polling from report generation"
      generator_lambda = "Processes queued reports and sends emails"
      s3_bucket = "Stores generated reports with lifecycle policies"
      cloudwatch = "Monitoring, logging, and alerting"
    }
    flow = "EventBridge → Polling Lambda → SQS Queue → Generator Lambda → S3 + SES"
    scalability = "Handles 1000+ reports with automatic scaling"
    cost_estimate = "~$10-20/month for typical enterprise usage"
  }
}
