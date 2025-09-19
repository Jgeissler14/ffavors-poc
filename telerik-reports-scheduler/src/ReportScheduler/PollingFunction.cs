using Amazon.Lambda.Core;
using Amazon.SQS;
using Amazon.SQS.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ReportScheduler
{
    public class PollingFunction
    {
        private readonly IAmazonSQS _sqsClient;
        private readonly string _queueUrl;
        private readonly string _apiUrl;
        private readonly HttpClient _httpClient;

        public PollingFunction()
        {
            _sqsClient = new AmazonSQSClient();
            _queueUrl = Environment.GetEnvironmentVariable("REPORT_QUEUE_URL");
            _apiUrl = Environment.GetEnvironmentVariable("API_URL");
            _httpClient = new HttpClient();

            if (string.IsNullOrEmpty(_queueUrl))
            {
                throw new InvalidOperationException("Environment variable REPORT_QUEUE_URL must be set.");
            }
            if (string.IsNullOrEmpty(_apiUrl))
            {
                throw new InvalidOperationException("Environment variable API_URL must be set.");
            }
        }

        public async Task<PollingResponse> FunctionHandler(ILambdaContext context)
        {
            var schedulesToRun = new List<Schedule>();
            var currentTime = DateTime.UtcNow;

            try
            {
                var response = await _httpClient.GetAsync($"{_apiUrl}/api/Schedules/1");
                response.EnsureSuccessStatusCode();
                var responseBody = await response.Content.ReadAsStringAsync();
                var apiResponse = JsonSerializer.Deserialize<ApiResponse>(responseBody, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (apiResponse != null && apiResponse.Schedules != null)
                {
                    var parametersByScheduleId = apiResponse.Parameters
                        .GroupBy(p => p.Schedule_ID)
                        .ToDictionary(g => g.Key, g => g.ToDictionary(p => p.Param_Name, p => p.Param_Value));

                    foreach (var schedData in apiResponse.Schedules)
                    {
                        Dictionary<string, string> parametersDict = null;
                        if (parametersByScheduleId.TryGetValue(schedData.reports_sched_id, out var p))
                        {
                            parametersDict = p;
                        }

                        var queryParams = new List<string>();
                        if (parametersDict != null)
                        {
                            foreach (var param in parametersDict)
                            {
                                if (!string.IsNullOrEmpty(param.Value))
                                {
                                    queryParams.Add($"{Uri.EscapeDataString(param.Key)}={Uri.EscapeDataString(param.Value)}");
                                }
                            }
                        }

                        schedulesToRun.Add(new Schedule
                        {
                            reports_sched_id = schedData.reports_sched_id,
                            report_name = schedData.report_name,
                            parameters = string.Join("&", queryParams),
                            toEmails = schedData.toEmails,
                            ccEmails = schedData.ccEmails,
                            Subject = schedData.Subject,
                            Body = schedData.Body
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                context.Logger.LogError($"API call failed: {ex.Message}");
                return new PollingResponse { Success = false, Message = $"API error: {ex.Message}", CheckTime = currentTime };
            }

            if (schedulesToRun.Count == 0)
            {
                return new PollingResponse { Success = true, Message = "No reports due to run.", CheckTime = currentTime };
            }

            context.Logger.LogInformation($"Found {schedulesToRun.Count} reports to schedule.");
            var queuedReports = new List<int>();

            foreach (var schedule in schedulesToRun)
            {
                try
                {
                    await PublishToQueue(schedule, context);
                    queuedReports.Add(schedule.reports_sched_id);
                    context.Logger.LogInformation($"Successfully queued schedule ID: {schedule.reports_sched_id}");
                }
                catch (Exception ex)
                {
                    context.Logger.LogError($"Failed to process schedule {schedule.reports_sched_id}: {ex.Message}");
                }
            }

            return new PollingResponse
            {
                Success = true,
                Message = $"Processed {schedulesToRun.Count} schedules, queued {queuedReports.Count} reports.",
                QueuedReportIds = queuedReports,
                CheckTime = currentTime
            };
        }

        private async Task PublishToQueue(Schedule schedule, ILambdaContext context)
        {
            if (string.IsNullOrEmpty(schedule.report_name))
            {
                throw new InvalidOperationException($"Report name is missing for schedule ID: {schedule.reports_sched_id}");
            }

            var message = new ReportQueueMessage
            {
                ReportName = schedule.report_name,
                Parameters = schedule.parameters,
                ScheduleId = schedule.reports_sched_id,
                ToEmails = schedule.toEmails,
                CcEmails = schedule.ccEmails,
                Subject = schedule.Subject,
                Body = schedule.Body
            };

            var messageBody = JsonSerializer.Serialize(message);
            
            var sendRequest = new SendMessageRequest
            {
                QueueUrl = _queueUrl,
                MessageBody = messageBody,
                MessageAttributes = new Dictionary<string, MessageAttributeValue>
                {
                    ["ReportName"] = new MessageAttributeValue { DataType = "String", StringValue = schedule.report_name },
                    ["ScheduleId"] = new MessageAttributeValue { DataType = "String", StringValue = schedule.reports_sched_id.ToString() }
                }
            };

            await _sqsClient.SendMessageAsync(sendRequest);
            context.Logger.LogInformation($"Sent message to SQS for Report Name: {schedule.report_name}");
        }
    }

    public class ApiResponse
    {
        public List<ScheduleData> Schedules { get; set; }
        public List<ParameterData> Parameters { get; set; }
    }

    public class ScheduleData
    {
        [JsonPropertyName("Schedule_ID")]
        public int reports_sched_id { get; set; }

        [JsonPropertyName("Report_Name")]
        public string report_name { get; set; }

        [JsonPropertyName("toEmails")]
        public string toEmails { get; set; }

        [JsonPropertyName("ccEmails")]
        public string ccEmails { get; set; }

        [JsonPropertyName("Subject")]
        public string Subject { get; set; }

        [JsonPropertyName("Body")]
        public string Body { get; set; }
    }

    public class ParameterData
    {
        [JsonPropertyName("Schedule_ID")]
        public int Schedule_ID { get; set; }

        [JsonPropertyName("Param_Name")]
        public string Param_Name { get; set; }

        [JsonPropertyName("Param_Value")]
        public string Param_Value { get; set; }
    }

    public class Schedule
    {
        public int reports_sched_id { get; set; }
        public string report_name { get; set; }
        public string parameters { get; set; }
        public string toEmails { get; set; }
        public string ccEmails { get; set; }
        public string Subject { get; set; }
        public string Body { get; set; }
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

    public class PollingResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public List<int> QueuedReportIds { get; set; } = new();
        public DateTime CheckTime { get; set; }
    }
}
