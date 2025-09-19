# Telerik Reports Scheduler and FFavors API - CloudFormation Deployment

This document provides the steps to deploy the Telerik Reports Scheduler and FFavors API using the provided CloudFormation templates.

This project is deployed using a root stack that orchestrates the deployment of several nested stacks, making the architecture easier to manage and understand.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **AWS CLI**: [Install and configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).
2.  **.NET SDK**: [.NET 8 SDK or later](https://dotnet.microsoft.com/download).
3.  **Docker**: [Install Docker](https://docs.docker.com/get-docker/).
4.  **An S3 bucket** to store the Lambda deployment packages and the CloudFormation templates.

## Deployment Steps

### 1. Build and Package the Lambda Functions

First, you need to build the .NET projects for the two Lambda functions and create `.zip` deployment packages.

```bash
# Navigate to the source directory
cd /Users/joshuageissler/work/ffavors-poc/telerik-reports-scheduler/src

# Build and publish the Polling function
cd ReportScheduler
dotnet publish -c Release -o ./publish
cd publish
zip -r ../../../polling-deployment.zip .
cd ../..

# Build and publish the Generator function
cd ReportGenerator
dotnet publish -c Release -o ./publish
cd publish
zip -r ../../../generator-deployment.zip .
cd ../../..
```

After running these commands, you will have `polling-deployment.zip` and `generator-deployment.zip` in the `telerik-reports-scheduler` directory.

### 2. Upload Artifacts to S3

Upload the generated Lambda `.zip` files and the CloudFormation templates to your S3 bucket.

```bash
# Upload Lambda packages
aws s3 cp polling-deployment.zip s3://telerik-reports-poc-bucket-dev/artifacts/polling-deployment.zip
aws s3 cp generator-deployment.zip s3://telerik-reports-poc-bucket-dev/artifacts/generator-deployment.zip

# Upload CloudFormation templates
aws s3 cp /Users/joshuageissler/work/ffavors-poc/telerik-reports-scheduler/cloudformation/ s3://telerik-reports-poc-bucket-dev/cloudformation/ --recursive
```

Replace `telerik-reports-poc-bucket-dev` with the name of your S3 bucket.

### 3. Deploy the CloudFormation Stack

Now, you can deploy the root CloudFormation stack using the AWS CLI. The root stack will then deploy the nested stacks.

```bash
aws cloudformation deploy \
  --template-file /Users/joshuageissler/work/ffavors-poc/telerik-reports-scheduler/cloudformation/root.yaml \
  --stack-name telerik-reports-scheduler-stack \
  --parameter-overrides \
    Environment=dev \
    FromEmail=jgeissler@eccoselect.com \
    AlarmEmail=jgeissler@eccoselect.com \
    VpcId=vpc-0c6b7e34ce137c4b7 \
    DbConnectionSsmParameterName=/ffavors/connection-string \
    PollingLambdaS3Bucket=telerik-reports-poc-bucket-dev \
    PollingLambdaS3Key=artifacts/polling-deployment.zip \
    GeneratorLambdaS3Bucket=telerik-reports-poc-bucket-dev \
    GeneratorLambdaS3Key=artifacts/generator-deployment.zip \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
```

**Replace the following values:**

*   `<your-verified-email@example.com>`: A sender email address verified in Amazon SES.
*   `<your-alarm-email@example.com>`: The email address to receive CloudWatch alarm notifications.
*   `<your-vpc-id>`: The ID of the VPC where you want to deploy the resources.
*   `<your-s3-bucket-name>`: The name of the S3 bucket where you uploaded the artifacts.

### 4. Build and Push Docker Images

After the stack is created, it will create two ECR repositories. You need to build the Docker images for the `ffavorsapi` and `telerik-report-generator` and push them to these repositories.

First, get the ECR repository URIs from the CloudFormation stack outputs:

```bash
aws cloudformation describe-stacks --stack-name telerik-reports-scheduler-stack --query "Stacks[0].Outputs[?OutputKey=='FfavorsApiEcrRepositoryUrl'].OutputValue" --output text

aws cloudformation describe-stacks --stack-name telerik-reports-scheduler-stack --query "Stacks[0].Outputs[?OutputKey=='TelerikReportGeneratorEcrUrl'].OutputValue" --output text
```

Then, build and push the images:

```bash
# Authenticate Docker to your ECR registry
aws ecr get-login-password --region <your-aws-region> | docker login --username AWS --password-stdin <your-aws-account-id>.dkr.ecr.<your-aws-region>.amazonaws.com

# Build and push the ffavorsapi image
cd /Users/joshuageissler/work/ffavors-poc/ffavorsapi
docker build -t <ffavorsapi-ecr-uri>:latest .
docker push <ffavorsapi-ecr-uri>:latest

# Build and push the telerik-report-generator image
cd /Users/joshuageissler/work/ffavors-poc/telerik-reports-scheduler/src/ReportGenerator
docker build -t <telerik-report-generator-ecr-uri>:latest .
docker push <telerik-report-generator-ecr-uri>:latest
```

**Replace the following values:**

*   `<your-aws-region>`: The AWS region where your stack is deployed.
*   `<your-aws-account-id>`: Your AWS account ID.
*   `<ffavorsapi-ecr-uri>`: The ECR repository URI for the `ffavorsapi`.
*   `<telerik-report-generator-ecr-uri>`: The ECR repository URI for the `telerik-report-generator`.

## Updating the Stack

To update the stack, you can modify the templates, upload them to S3, and then run the `aws cloudformation deploy` command again.

## Deleting the Stack

To delete the stack and all its resources, run the following command:

```bash
aws cloudformation delete-stack --stack-name telerik-reports-scheduler-stack
```