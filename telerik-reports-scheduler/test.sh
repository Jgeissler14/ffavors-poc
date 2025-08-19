#!/bin/bash

# Simple Test Script for Telerik Reports Scheduler
set -e

# Configuration
QUEUE_URL="https://sqs.us-east-1.amazonaws.com/858946449855/telerik-reports-queue-dev"
S3_BUCKET="telerik-reports-poc-bucket-dev"
TEST_EMAIL="jgeissler@eccoselect.com"

echo "🚀 Testing Telerik Reports Scheduler..."

# Send test message
echo "Sending test report to queue..."
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MESSAGE='{"ReportId":"test-'$(date +%s)'","ReportName":"Test Report","ReportType":"TestReport","Recipients":["'$TEST_EMAIL'"],"Parameters":{},"QueuedAt":"'$TIMESTAMP'","Priority":1}'

MESSAGE_ID=$(aws sqs send-message --queue-url $QUEUE_URL --message-body "$MESSAGE" --output text --query 'MessageId')
echo "✅ Message sent! ID: $MESSAGE_ID"

# Wait for processing
echo "⏳ Waiting 30 seconds for processing..."
sleep 30

# Check results
QUEUE_DEPTH=$(aws sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names ApproximateNumberOfMessages --output text --query 'Attributes.ApproximateNumberOfMessages')
echo "Queue depth: $QUEUE_DEPTH messages"

# Check S3
REPORTS_TODAY=$(aws s3 ls s3://$S3_BUCKET/reports/ --recursive | grep "$(date +%Y-%m-%d)" | wc -l)
echo "Reports generated today: $REPORTS_TODAY"

echo "🎉 Test completed! Check your email for the report."

# Show monitoring commands
echo ""
echo "💡 Monitor with:"
echo "aws logs tail /aws/lambda/telerik-reports-generator-dev --follow"
echo "aws s3 ls s3://$S3_BUCKET/reports/ --recursive --human-readable"
