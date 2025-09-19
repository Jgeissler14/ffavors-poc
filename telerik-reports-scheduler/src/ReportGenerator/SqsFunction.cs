using Amazon.Lambda.Core;
using Amazon.Lambda.SQSEvents;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ReportGenerator
{
    public class SqsFunction
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiUrl;

        public SqsFunction()
        {
            _httpClient = new HttpClient();
            _apiUrl = Environment.GetEnvironmentVariable("API_URL");
            if (string.IsNullOrEmpty(_apiUrl))
            {
                throw new InvalidOperationException("Environment variable API_URL must be set.");
            }
        }

        public async Task FunctionHandler(SQSEvent sqsEvent, ILambdaContext context)
        {
            foreach (var record in sqsEvent.Records)
            {
                try
                {
                    await ProcessReportMessage(record, context);
                }
                catch (Exception ex)
                {
                    context.Logger.LogError($"Error processing message {record.MessageId}: {ex.Message}");
                    throw; 
                }
            }
        }

        private async Task ProcessReportMessage(SQSEvent.SQSMessage message, ILambdaContext context)
        {
            context.Logger.LogInformation($"Processing report message: {message.MessageId}");

            var reportRequest = JsonSerializer.Deserialize<ReportQueueMessage>(message.Body);

            if (reportRequest == null)
            {
                context.Logger.LogError($"Failed to deserialize SQS message body for message {message.MessageId}");
                return;
            }
            
            context.Logger.LogInformation($"Generating report: {reportRequest.ReportName} (Schedule ID: {reportRequest.ScheduleId})");

            var executionId = Guid.NewGuid().ToString();
            var startTime = DateTime.UtcNow;

            try
            {
                var url = $"{_apiUrl}/api/Schedules/GetFile/{reportRequest.ReportName}/{reportRequest.Parameters}";
                var response = await _httpClient.GetAsync(url);
                response.EnsureSuccessStatusCode();
                var reportBytes = await response.Content.ReadAsByteArrayAsync();

                var mockS3Key = MockUploadToS3(reportBytes, reportRequest, executionId, context);
                
                MockSendEmailWithAttachment(reportBytes, reportRequest, context);
                
                var duration = DateTime.UtcNow - startTime;
                context.Logger.LogInformation($"Report {reportRequest.ReportName} completed successfully (mocked) in {duration.TotalSeconds:F2}s. Mock S3 Key: {mockS3Key}");
            }
            catch (Exception ex)
            {
                var duration = DateTime.UtcNow - startTime;
                context.Logger.LogError($"Report {reportRequest.ReportName} failed after {duration.TotalSeconds:F2}s: {ex.Message}");
                throw; 
            }
        }

        private string MockUploadToS3(byte[] reportBytes, ReportQueueMessage request, string executionId, ILambdaContext context)
        {
            var bucketName = Environment.GetEnvironmentVariable("REPORTS_BUCKET") ?? "mock-bucket";
            var timestamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
            var fileExtension = "pdf";
            var key = $"reports/{request.ScheduleId}/{DateTime.UtcNow:yyyy/MM/dd}/{request.ReportName}_{timestamp}_{executionId[..8]}.{fileExtension}";
            
            context.Logger.LogInformation("--- S3 SIMULATION ---");
            context.Logger.LogInformation($"Bucket: {bucketName}");
            context.Logger.LogInformation($"Key: {key}");
            context.Logger.LogInformation($"Size: {reportBytes.Length:N0} bytes");
            context.Logger.LogInformation("--- END S3 SIMULATION ---");
            
            return key;
        }

        private void MockSendEmailWithAttachment(byte[] reportBytes, ReportQueueMessage request, ILambdaContext context)
        {
            var toAddresses = request.ToEmails?.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries).ToList() ?? new List<string>();
            var ccAddresses = request.CcEmails?.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries).ToList() ?? new List<string>();

            if (toAddresses.Count == 0 && ccAddresses.Count == 0)
            {
                context.Logger.LogWarning($"No recipients found for schedule ID: {request.ScheduleId}.");
                return;
            }

            var fromEmail = Environment.GetEnvironmentVariable("FROM_EMAIL") ?? "mock-sender@example.com";
            
            var subject = !string.IsNullOrEmpty(request.Subject) 
                ? request.Subject 
                : $"{request.ReportName} - {DateTime.UtcNow:yyyy-MM-dd}";

            var body = !string.IsNullOrEmpty(request.Body) 
                ? request.Body
                : $"Your report, {request.ReportName}, is attached.";

            context.Logger.LogInformation("--- EMAIL SIMULATION ---");
            context.Logger.LogInformation($"From: {fromEmail}");
            context.Logger.LogInformation($"To: {string.Join(",", toAddresses)}");
            context.Logger.LogInformation($"CC: {string.Join(",", ccAddresses)}");
            context.Logger.LogInformation($"Subject: {subject}");
            context.Logger.LogInformation($"Body: {body}");
            context.Logger.LogInformation($"Attachment: {request.ReportName}.pdf ({reportBytes.Length:N0} bytes)");
            context.Logger.LogInformation("--- END EMAIL SIMULATION ---");
        }
    }

    public class ReportQueueMessage
    {
        public string ReportName { get; set; }
        public string Parameters { get; set; }
        public int ScheduleId { get; set; }
        public string ToEmails { get; set; } 
        public string CcEmails { get; set; }
        public string Subject { get; set; }
        public string Body { get; set; }
    }
}
