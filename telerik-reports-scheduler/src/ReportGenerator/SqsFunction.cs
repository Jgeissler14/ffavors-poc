using Telerik.Reporting;
using Telerik.Reporting.Processing;
using Telerik.Reporting.Drawing;
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
            // context.Logger.LogInformation($"Processing {sqsEvent.Records.Count} SQS messages");

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

            if (reportRequest == null)
            {
                context.Logger.LogError($"Failed to deserialize SQS message body for message {message.MessageId}");
                return; // Or throw an exception if you want SQS to retry
            }
            
            context.Logger.LogInformation($"Generating report: {reportRequest.ReportName} (ID: {reportRequest.ReportId})");

            var executionId = Guid.NewGuid().ToString();
            var startTime = DateTime.UtcNow;

            try
            {
                // Generate the report
                var reportBytes = GenerateReport(reportRequest, context);
                
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

        private byte[] GenerateReport(ReportQueueMessage request, ILambdaContext context)
        {
            context.Logger.LogInformation($"Generating Telerik report of type: {request.ReportType}");

            // Create a new blank report
            var report = new Telerik.Reporting.Report();
            report.Name = request.ReportName;

            // Add a PageHeader section
            var pageHeader = new Telerik.Reporting.PageHeaderSection();
            pageHeader.Height = Telerik.Reporting.Drawing.Unit.Cm(1);
            report.Items.Add(pageHeader);

            // Add a TextBox to the PageHeader
            var titleTextBox = new Telerik.Reporting.TextBox();
            titleTextBox.Value = $"Report: {request.ReportName} (ID: {request.ReportId})";
            titleTextBox.Location = new Telerik.Reporting.Drawing.PointU(Telerik.Reporting.Drawing.Unit.Cm(0.5), Telerik.Reporting.Drawing.Unit.Cm(0.2));
            titleTextBox.Size = new Telerik.Reporting.Drawing.SizeU(Telerik.Reporting.Drawing.Unit.Cm(15), Telerik.Reporting.Drawing.Unit.Cm(0.6));
            titleTextBox.Style.Font.Size = Telerik.Reporting.Drawing.Unit.Point(14);
            titleTextBox.Style.Font.Bold = true;
            pageHeader.Items.Add(titleTextBox);

            // Add a Detail section
            var detailSection = new Telerik.Reporting.DetailSection();
            detailSection.Height = Telerik.Reporting.Drawing.Unit.Cm(2);
            report.Items.Add(detailSection);

            // Add a TextBox to the Detail section
            var contentTextBox = new Telerik.Reporting.TextBox();
            contentTextBox.Value = $"This is a basic Telerik report generated for {request.ReportType}.\n" +
                                   $"Generated at: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC\n" +
                                   $"Schedule ID: {request.ScheduleId}";
            contentTextBox.Location = new Telerik.Reporting.Drawing.PointU(Telerik.Reporting.Drawing.Unit.Cm(0.5), Telerik.Reporting.Drawing.Unit.Cm(0.2));
            contentTextBox.Size = new Telerik.Reporting.Drawing.SizeU(Telerik.Reporting.Drawing.Unit.Cm(18), Telerik.Reporting.Drawing.Unit.Cm(1.5));
            detailSection.Items.Add(contentTextBox);

            // Process the report
            var reportProcessor = new Telerik.Reporting.Processing.ReportProcessor();
            var instanceReportSource = new Telerik.Reporting.InstanceReportSource();
            instanceReportSource.ReportDocument = report;

            Telerik.Reporting.Processing.RenderingResult result = reportProcessor.RenderReport(request.OutputFormat, instanceReportSource, null);

            if (result.HasErrors)
            {
                foreach (var error in result.Errors)
                {
                    context.Logger.LogError($"Telerik Reporting Error: {error.Message}");
                }
                throw new Exception("Telerik Report generation failed.");
            }

            context.Logger.LogInformation($"Telerik Report generated successfully. Size: {result.DocumentBytes.Length} bytes");
            return result.DocumentBytes;
        }


        private async Task<string> UploadToS3(byte[] reportBytes, ReportQueueMessage request, string executionId, ILambdaContext context)
        {
            var bucketName = Environment.GetEnvironmentVariable("REPORTS_BUCKET");
            var timestamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
            var fileExtension = GetFileExtension(request.OutputFormat);
            var key = $"reports/{request.ReportId.ToString()}/{DateTime.UtcNow:yyyy/MM/dd}/{request.ReportName}_{timestamp}_{executionId[..8]}.{fileExtension}";
            
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
                    ["report-id"] = request.ReportId.ToString(),
                    ["schedule-id"] = request.ScheduleId.ToString(),
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
- Schedule ID: {request.ScheduleId.ToString()}
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
                "HTML" => "html",
                "MHTML" => "mhtml",
                "RTF" => "rtf",
                "TIFF" => "tiff",
                "XPS" => "xps",
                _ => "pdf" // Default to PDF if format is not recognized
            };
        }

        private string GetContentType(string format)
        {
            return format.ToUpper() switch
            {
                "PDF" => "application/pdf",
                "XLSX" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "CSV" => "text/csv",
                "HTML" => "text/html",
                "MHTML" => "message/rfc822",
                "RTF" => "application/rtf",
                "TIFF" => "image/tiff",
                "XPS" => "application/vnd.ms-xpsdocument",
                _ => "application/octet-stream" // Default to octet-stream if format is not recognized
            };
        }
    }

    // Shared message class (same as in PollingFunction)
    public class ReportQueueMessage
    {
        public long ReportId { get; set; }
        public long ScheduleId { get; set; }
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
