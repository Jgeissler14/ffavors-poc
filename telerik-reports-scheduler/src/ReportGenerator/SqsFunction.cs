using Amazon.Lambda.Core;
using Amazon.Lambda.SQSEvents;
using Amazon.S3;
using Amazon.S3.Model;
using Amazon.SimpleEmail;
using Amazon.SimpleEmail.Model;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ReportGenerator
{
    public class SqsFunction
    {
        private readonly IAmazonS3 _s3Client;
        private readonly IAmazonSimpleEmailService _sesClient;

        public SqsFunction()
        {
            _s3Client = new AmazonS3Client();
            _sesClient = new AmazonSimpleEmailServiceClient();
        }

        public async Task FunctionHandler(SQSEvent sqsEvent, ILambdaContext context)
        {
            context.Logger.LogInformation($"Processing {sqsEvent.Records.Count} SQS messages");

            foreach (var record in sqsEvent.Records)
            {
                try
                {
                    await ProcessReportMessage(record, context);
                }
                catch (Exception ex)
                {
                    context.Logger.LogError($"Error processing message {record.MessageId}: {ex.Message}");
                    // SQS will retry failed messages based on the queue configuration
                    throw; // Re-throw to trigger SQS retry mechanism
                }
            }
        }

        private async Task ProcessReportMessage(SQSEvent.SQSMessage message, ILambdaContext context)
        {
            context.Logger.LogInformation($"Processing report message: {message.MessageId}");

            // Parse the message body
            var reportRequest = JsonSerializer.Deserialize<ReportQueueMessage>(message.Body);
            
            context.Logger.LogInformation($"Generating report: {reportRequest.ReportName} (ID: {reportRequest.ReportId})");

            var executionId = Guid.NewGuid().ToString();
            var startTime = DateTime.UtcNow;

            try
            {
                // Generate the report
                var reportBytes = await GenerateReport(reportRequest, context);
                
                // Upload to S3
                var s3Key = await UploadToS3(reportBytes, reportRequest, executionId, context);
                
                // Send emails to recipients
                await SendEmailsToRecipients(reportBytes, reportRequest, s3Key, context);
                
                var duration = DateTime.UtcNow - startTime;
                context.Logger.LogInformation($"Report {reportRequest.ReportId} completed successfully in {duration.TotalSeconds:F2}s. S3 Key: {s3Key}");
            }
            catch (Exception ex)
            {
                var duration = DateTime.UtcNow - startTime;
                context.Logger.LogError($"Report {reportRequest.ReportId} failed after {duration.TotalSeconds:F2}s: {ex.Message}");
                throw; // Re-throw to trigger SQS retry
            }
        }

        private async Task<byte[]> GenerateReport(ReportQueueMessage request, ILambdaContext context)
        {
            context.Logger.LogInformation($"Generating report of type: {request.ReportType}");
            
            // TODO: Replace with actual Telerik report generation
            // For now, generate mock report based on configuration
            var reportContent = GenerateMockReport(request);
            var reportBytes = Encoding.UTF8.GetBytes(reportContent);
            
            context.Logger.LogInformation($"Report generated successfully. Size: {reportBytes.Length} bytes");
            return reportBytes;
        }

        private string GenerateMockReport(ReportQueueMessage request)
        {
            var timestamp = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
            var queueDelay = DateTime.UtcNow - request.QueuedAt;
            
            var reportContent = new StringBuilder();
            reportContent.AppendLine($"{request.ReportName}");
            reportContent.AppendLine("".PadRight(request.ReportName.Length, '='));
            reportContent.AppendLine($"Generated: {timestamp} UTC");
            reportContent.AppendLine($"Queued: {request.QueuedAt:yyyy-MM-dd HH:mm:ss} UTC");
            reportContent.AppendLine($"Queue Delay: {queueDelay.TotalSeconds:F2} seconds");
            reportContent.AppendLine();
            
            reportContent.AppendLine("REPORT CONFIGURATION");
            reportContent.AppendLine("===================");
            reportContent.AppendLine($"Report ID: {request.ReportId}");
            reportContent.AppendLine($"Schedule ID: {request.ScheduleId}");
            reportContent.AppendLine($"Report Type: {request.ReportType}");
            reportContent.AppendLine($"Template: {request.TemplatePath}");
            reportContent.AppendLine($"Output Format: {request.OutputFormat}");
            reportContent.AppendLine($"Priority: {request.Priority}");
            reportContent.AppendLine($"Recipients: {request.Recipients.Count}");
            reportContent.AppendLine();
            
            reportContent.AppendLine("PARAMETERS");
            reportContent.AppendLine("==========");
            foreach (var param in request.Parameters)
            {
                reportContent.AppendLine($"- {param.Key}: {param.Value}");
            }
            reportContent.AppendLine();
            
            reportContent.AppendLine("SAMPLE DATA (Mock)");
            reportContent.AppendLine("==================");
            
            // Generate different mock data based on report type
            switch (request.ReportType)
            {
                case "DailySalesReport":
                    reportContent.AppendLine("DAILY SALES SUMMARY");
                    reportContent.AppendLine($"Date: {DateTime.UtcNow.AddDays(-1):yyyy-MM-dd}");
                    reportContent.AppendLine($"Total Sales: ${Random.Shared.Next(10000, 50000):N2}");
                    reportContent.AppendLine($"Transactions: {Random.Shared.Next(100, 500)}");
                    reportContent.AppendLine($"Average Order: ${Random.Shared.Next(50, 200):N2}");
                    reportContent.AppendLine($"Top Product: Product-{Random.Shared.Next(1, 100)}");
                    break;
                    
                case "WeeklyInventoryReport":
                    reportContent.AppendLine("WEEKLY INVENTORY SUMMARY");
                    reportContent.AppendLine($"Week Ending: {DateTime.UtcNow.AddDays(-1):yyyy-MM-dd}");
                    reportContent.AppendLine($"Total Items: {Random.Shared.Next(1000, 5000)}");
                    reportContent.AppendLine($"Low Stock Items: {Random.Shared.Next(10, 50)}");
                    reportContent.AppendLine($"Out of Stock: {Random.Shared.Next(0, 10)}");
                    reportContent.AppendLine($"Reorder Required: {Random.Shared.Next(5, 25)}");
                    break;
                    
                case "MonthlyFinancialReport":
                    reportContent.AppendLine("MONTHLY FINANCIAL SUMMARY");
                    reportContent.AppendLine($"Month: {DateTime.UtcNow.AddMonths(-1):yyyy-MM}");
                    reportContent.AppendLine($"Revenue: ${Random.Shared.Next(100000, 500000):N2}");
                    reportContent.AppendLine($"Expenses: ${Random.Shared.Next(50000, 200000):N2}");
                    reportContent.AppendLine($"Net Profit: ${Random.Shared.Next(20000, 100000):N2}");
                    reportContent.AppendLine($"Profit Margin: {Random.Shared.Next(15, 35)}%");
                    break;
                    
                case "SystemStatusReport":
                    reportContent.AppendLine("SYSTEM STATUS SUMMARY");
                    reportContent.AppendLine($"Check Time: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");
                    reportContent.AppendLine($"System Uptime: {Random.Shared.Next(95, 100):F2}%");
                    reportContent.AppendLine($"Active Users: {Random.Shared.Next(50, 200)}");
                    reportContent.AppendLine($"Response Time: {Random.Shared.Next(100, 500)}ms");
                    reportContent.AppendLine($"Error Rate: {Random.Shared.NextDouble() * 2:F3}%");
                    break;
                    
                default:
                    reportContent.AppendLine($"Sample data for {request.ReportType}");
                    reportContent.AppendLine($"Generated at: {timestamp}");
                    reportContent.AppendLine($"Data points: {Random.Shared.Next(100, 1000)}");
                    break;
            }
            
            reportContent.AppendLine();
            reportContent.AppendLine("PROCESSING DETAILS");
            reportContent.AppendLine("==================");
            reportContent.AppendLine($"Queue Processing Time: {queueDelay.TotalMilliseconds:F0}ms");
            reportContent.AppendLine($"Report Generation: {Random.Shared.Next(500, 2000)}ms");
            reportContent.AppendLine($"Generated By: AWS Lambda Report Generator (SQS-Driven)");
            reportContent.AppendLine($"Template Path: {request.TemplatePath}");
            reportContent.AppendLine();
            reportContent.AppendLine("This is a mock report. Replace this section with actual Telerik report generation logic.");
            
            return reportContent.ToString();
        }

        private async Task<string> UploadToS3(byte[] reportBytes, ReportQueueMessage request, string executionId, ILambdaContext context)
        {
            var bucketName = Environment.GetEnvironmentVariable("REPORTS_BUCKET");
            var timestamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
            var fileExtension = GetFileExtension(request.OutputFormat);
            var key = $"reports/{request.ReportId}/{DateTime.UtcNow:yyyy/MM/dd}/{request.ReportName}_{timestamp}_{executionId[..8]}.{fileExtension}";
            
            context.Logger.LogInformation($"Uploading report to S3: {bucketName}/{key}");
            
            using var stream = new MemoryStream(reportBytes);
            await _s3Client.PutObjectAsync(new PutObjectRequest
            {
                BucketName = bucketName,
                Key = key,
                InputStream = stream,
                ContentType = GetContentType(request.OutputFormat),
                ServerSideEncryptionMethod = ServerSideEncryptionMethod.AES256,
                Metadata = {
                    ["report-id"] = request.ReportId,
                    ["schedule-id"] = request.ScheduleId,
                    ["execution-id"] = executionId,
                    ["generated-at"] = DateTime.UtcNow.ToString("O"),
                    ["queued-at"] = request.QueuedAt.ToString("O"),
                    ["priority"] = request.Priority.ToString()
                }
            });
            
            context.Logger.LogInformation($"Report uploaded successfully to: {key}");
            return key;
        }

        private async Task SendEmailsToRecipients(byte[] reportBytes, ReportQueueMessage request, string s3Key, ILambdaContext context)
        {
            if (request.Recipients.Count == 0)
            {
                context.Logger.LogWarning("No recipients configured for this report");
                return;
            }
            
            context.Logger.LogInformation($"Sending emails to {request.Recipients.Count} recipients");
            
            var fromEmail = Environment.GetEnvironmentVariable("FROM_EMAIL");
            var bucketName = Environment.GetEnvironmentVariable("REPORTS_BUCKET");
            
            // Generate presigned URL
            var downloadUrl = await _s3Client.GetPreSignedURLAsync(new GetPreSignedUrlRequest
            {
                BucketName = bucketName,
                Key = s3Key,
                Verb = HttpVerb.GET,
                Expires = DateTime.UtcNow.AddDays(7)
            });
            
            var subject = $"{request.ReportName} - {DateTime.UtcNow:yyyy-MM-dd}";
            var emailBody = GenerateEmailBody(request, downloadUrl, reportBytes.Length);
            
            var sendRequest = new SendEmailRequest
            {
                Source = fromEmail,
                Destination = new Destination
                {
                    ToAddresses = request.Recipients
                },
                Message = new Message
                {
                    Subject = new Content(subject),
                    Body = new Body
                    {
                        Text = new Content(emailBody)
                    }
                }
            };
            
            await _sesClient.SendEmailAsync(sendRequest);
            context.Logger.LogInformation("Emails sent successfully");
        }

        private string GenerateEmailBody(ReportQueueMessage request, string downloadUrl, int reportSize)
        {
            var queueDelay = DateTime.UtcNow - request.QueuedAt;
            
            return $@"TELERIK REPORTS SCHEDULER
========================

Your {request.ReportName} is ready for download.

Report Details:
- Report ID: {request.ReportId}
- Schedule ID: {request.ScheduleId}
- Report Name: {request.ReportName}
- Generated: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC
- Queued: {request.QueuedAt:yyyy-MM-dd HH:mm:ss} UTC
- Processing Time: {queueDelay.TotalSeconds:F2} seconds
- Format: {request.OutputFormat}
- File Size: {reportSize:N0} bytes
- Priority: {request.Priority}

DOWNLOAD YOUR REPORT:
{downloadUrl}

Important Notes:
- This download link expires in 7 days ({DateTime.UtcNow.AddDays(7):yyyy-MM-dd HH:mm:ss} UTC)
- The report is securely stored in AWS S3
- Click or copy the link above to download your report

Report Configuration:
{string.Join("\n", request.Parameters.Select(p => $"- {p.Key}: {p.Value}"))}

Processing Details:
- Template: {request.TemplatePath}
- Queue Delay: {queueDelay.TotalMilliseconds:F0}ms
- Generated via SQS Queue Processing

---
This is an automated message from the Telerik Reports Scheduler.
Generated by AWS Lambda | Powered by Telerik Reporting | SQS Queue Processing

If you have questions, contact your system administrator.";
        }

        private string GetFileExtension(string format)
        {
            return format.ToUpper() switch
            {
                "PDF" => "pdf",
                "XLSX" => "xlsx",
                "CSV" => "csv",
                "TXT" => "txt",
                _ => "pdf"
            };
        }

        private string GetContentType(string format)
        {
            return format.ToUpper() switch
            {
                "PDF" => "application/pdf",
                "XLSX" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "CSV" => "text/csv",
                "TXT" => "text/plain",
                _ => "application/octet-stream"
            };
        }
    }

    // Shared message class (same as in PollingFunction)
    public class ReportQueueMessage
    {
        public string ReportId { get; set; } = string.Empty;
        public string ScheduleId { get; set; } = string.Empty;
        public string ReportName { get; set; } = string.Empty;
        public string ReportType { get; set; } = string.Empty;
        public string TemplatePath { get; set; } = string.Empty;
        public string OutputFormat { get; set; } = "PDF";
        public Dictionary<string, object> Parameters { get; set; } = new();
        public List<string> Recipients { get; set; } = new();
        public DateTime QueuedAt { get; set; }
        public int Priority { get; set; } = 2;
    }
}
