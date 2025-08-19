# Telerik Reports Scheduler

SQS-based serverless report generation system using AWS Lambda, SQS, S3, and SES.

## 🏗️ Architecture

```
EventBridge (8 AM UTC) → Polling Lambda → SQS Queue → Generator Lambda → S3 + SES
```

- **Polling Lambda**: Checks schedules daily and queues reports
- **Generator Lambda**: Processes queued reports and sends emails
- **SQS Queue**: Decouples polling from generation (batch processing)
- **S3 Storage**: Stores reports with presigned URLs for download
- **Email Delivery**: Corporate-friendly plain text with download links

## 📁 Project Structure

```
├── src/
│   ├── ReportGenerator/     # SQS-triggered report generator Lambda
│   └── ReportScheduler/     # EventBridge-triggered polling Lambda
├── terraform/
│   ├── main.tf             # Infrastructure definition
│   ├── variables.tf        # Configuration variables
│   ├── outputs.tf          # System outputs
│   └── terraform.tfvars    # Environment values
├── test.sh                 # System test script
└── README.md              # This file
```

## 🚀 Quick Start

### 1. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply -var-file="terraform.tfvars"
```

### 2. Test the System
```bash
./test.sh
```

## 🧪 Testing

The `test.sh` script:
- Sends a test message to the SQS queue
- Waits for processing
- Checks queue status and S3 reports
- Provides monitoring commands

**Expected result**: Report generated in S3 and email sent with download link.

## 📊 Monitoring

```bash
# View real-time logs
aws logs tail /aws/lambda/telerik-reports-generator-dev --follow

# Check queue status
aws sqs get-queue-attributes --queue-url https://sqs.us-east-1.amazonaws.com/285824578675/telerik-reports-queue-dev --attribute-names ApproximateNumberOfMessages

# List generated reports
aws s3 ls s3://telerik-reports-poc-bucket-dev/reports/ --recursive --human-readable
```

## ⚙️ Configuration

Key settings in `terraform/terraform.tfvars`:
- `from_email`: Sender email address (must be verified in SES)
- `alarm_email`: Email for system alerts
- `environment`: Deployment environment (dev/prod)
- `aws_region`: AWS region for deployment

## 🗄️ Database Connection

The database connection string is managed via AWS Systems Manager (SSM) Parameter Store. The Terraform configuration reads the connection string from the SSM parameter specified in `terraform/variables.tf` (variable: `db_connection_ssm_parameter_name`).

The connection string must be in the following PostgreSQL format:

`Host=<your-rds-host>;Port=5432;Username=<your-username>;Password=<your-password>;Database=<your-database>`

## 🎯 Features

- **Mock Data**: 5 embedded report types (no database required)
- **Scalable**: Handles 1000+ reports with auto-scaling
- **Cost Effective**: ~$10-20/month estimated cost
- **Corporate Friendly**: Plain text emails bypass filters
- **Secure**: Presigned S3 URLs with 7-day expiration
- **Monitored**: CloudWatch alarms for all failure scenarios

## 🔧 Cleanup

```bash
cd terraform
terraform destroy -var-file="terraform.tfvars"
```
