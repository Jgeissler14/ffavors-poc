using Amazon.Lambda.Core;
using Amazon.SQS;
using Amazon.SQS.Model;
using Npgsql;
using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;


[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ReportScheduler
{
    public class PollingFunction
    {
        private readonly IAmazonSQS _sqsClient;
        private readonly string _queueUrl;
        private readonly string _dbConnectionString;

        public PollingFunction()
        {
            _sqsClient = new AmazonSQSClient();
            _queueUrl = Environment.GetEnvironmentVariable("REPORT_QUEUE_URL");
            _dbConnectionString = Environment.GetEnvironmentVariable("DB_CONNECTION");

            if (string.IsNullOrEmpty(_queueUrl) || string.IsNullOrEmpty(_dbConnectionString))
            {
                throw new InvalidOperationException("Environment variables REPORT_QUEUE_URL and DB_CONNECTION must be set.");
            }
        }

        public async Task<PollingResponse> FunctionHandler(ILambdaContext context)
        {
            var schedulesToRun = new List<ReportsSchedulerInfo>();
            var currentTime = DateTime.UtcNow;

            // 1. Fetch schedules from the database
            try
            {
                await using var conn = new NpgsqlConnection(_dbConnectionString);
                await conn.OpenAsync();

                var query = @"SELECT reports_sched_id, report_id, param_id, app_id, next_run_day, requestor, next_run_date_time, last_run_date_time, auto_sched, transdate 
                            FROM reports_scheduler WHERE next_run_date_time <= @CurrentTime AND auto_sched = 'Y'";
                
                await using var cmd = new NpgsqlCommand(query, conn);
                cmd.Parameters.AddWithValue("CurrentTime", currentTime);

                await using var reader = await cmd.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    schedulesToRun.Add(new ReportsSchedulerInfo
                    {
                        Reports_Sched_ID = reader.GetInt32(0),
                        Report_ID = reader.IsDBNull(1) ? (int?)null : reader.GetInt32(1),
                        Param_ID = reader.IsDBNull(2) ? (int?)null : reader.GetInt32(2),
                        App_ID = reader.IsDBNull(3) ? (int?)null : reader.GetInt32(3),
                        Next_Run_Day = reader.IsDBNull(4) ? null : reader.GetString(4),
                        Requestor = reader.IsDBNull(5) ? null : reader.GetString(5),
                        Next_Run_Date_Time = reader.IsDBNull(6) ? (DateTime?)null : reader.GetDateTime(6),
                        Last_Run_Date_Time = reader.IsDBNull(7) ? (DateTime?)null : reader.GetDateTime(7),
                        Auto_Sched = reader.IsDBNull(8) ? null : reader.GetString(8),
                        TransDate = reader.IsDBNull(9) ? (DateTime?)null : reader.GetDateTime(9)
                    });
                }
            }
            catch (Exception ex)
            {
                context.Logger.LogError($"Database query failed: {ex.Message}");
                return new PollingResponse { Success = false, Message = $"Database error: {ex.Message}", CheckTime = currentTime };
            }

            if (schedulesToRun.Count == 0)
            {
                return new PollingResponse { Success = true, Message = "No reports due to run.", CheckTime = currentTime };
            }

            context.Logger.LogInformation($"Found {schedulesToRun.Count} reports to schedule.");
            var queuedReports = new List<int>();

            // 2. Queue reports and update the database
            foreach (var schedule in schedulesToRun)
            {
                try
                {
                    await PublishToQueue(schedule, context);
                    await UpdateScheduleInDb(schedule, currentTime, context);
                    queuedReports.Add(schedule.Reports_Sched_ID);
                    context.Logger.LogInformation($"Successfully queued and updated schedule ID: {schedule.Reports_Sched_ID}");
                }
                catch (Exception ex)
                {
                    context.Logger.LogError($"Failed to process schedule {schedule.Reports_Sched_ID}: {ex.Message}");
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

        private async Task PublishToQueue(ReportsSchedulerInfo schedule, ILambdaContext context)
        {
            var message = new ReportQueueMessage
            {
                ReportId = schedule.Report_ID,
                ScheduleId = schedule.Reports_Sched_ID,
                Parameters = new Dictionary<string, object>
                {
                    ["ParamId"] = schedule.Param_ID?.ToString() ?? "",
                    ["AppId"] = schedule.App_ID?.ToString() ?? ""
                },
                // TODO: Get the recipients from the database or configuration
                Recipients = new List<string> { "jgeissler@eccoselect.com" }, // Default recipient if none specified
                QueuedAt = DateTime.UtcNow
            };

            var messageBody = JsonSerializer.Serialize(message);
            
            var sendRequest = new SendMessageRequest
            {
                QueueUrl = _queueUrl,
                MessageBody = messageBody,
                MessageAttributes = new Dictionary<string, MessageAttributeValue>
                {
                    ["ReportId"] = new MessageAttributeValue { DataType = "String", StringValue = schedule.Report_ID.ToString() },
                    ["ScheduleId"] = new MessageAttributeValue { DataType = "String", StringValue = schedule.Reports_Sched_ID.ToString() }
                }
            };

            await _sqsClient.SendMessageAsync(sendRequest);
            context.Logger.LogInformation($"Sent message to SQS for Report ID: {schedule.Report_ID}");
        }

        private async Task UpdateScheduleInDb(ReportsSchedulerInfo schedule, DateTime runTime, ILambdaContext context)
        {
            try
            {
                await using var conn = new NpgsqlConnection(_dbConnectionString);
                await conn.OpenAsync();

                // Calculate next run time, assuming weekly schedule if Next_Run_Day is set
                var nextRun = schedule.Next_Run_Date_Time?.AddDays(7) ?? runTime.AddDays(7);

                var query = @"update public.reports_scheduler 
                            set last_run_date_time = @LastRun, next_run_date_time = @NextRun 
                            where reports_sched_id = @ScheduleId";

                await using var cmd = new NpgsqlCommand(query, conn);
                cmd.Parameters.AddWithValue("LastRun", runTime);
                cmd.Parameters.AddWithValue("NextRun", nextRun);
                cmd.Parameters.AddWithValue("ScheduleId", schedule.Reports_Sched_ID);

                var rowsAffected = await cmd.ExecuteNonQueryAsync();
                if (rowsAffected == 0)
                {
                    context.Logger.LogWarning($"Update failed: No rows affected for Schedule ID: {schedule.Reports_Sched_ID}");
                }
            }
            catch (Exception ex)
            {
                context.Logger.LogError($"Failed to update schedule {schedule.Reports_Sched_ID} in DB: {ex.Message}");
                // Throw to ensure the caller knows the update failed
                throw;
            }
        }
    }

    // Maps to the Reports_Scheduler table
    public class ReportsSchedulerInfo
    {
        public int Reports_Sched_ID { get; set; }
        public int? Report_ID { get; set; }
        public int? Param_ID { get; set; }
        public int? App_ID { get; set; }
        public string Next_Run_Day { get; set; }
        public string Requestor { get; set; }
        public DateTime? Next_Run_Date_Time { get; set; }
        public DateTime? Last_Run_Date_Time { get; set; }
        public string Auto_Sched { get; set; }
        public DateTime? TransDate { get; set; }
    }

    public class ReportQueueMessage
    {
        public int? ReportId { get; set; }
        public int ScheduleId { get; set; }
        public List<string> Recipients { get; set; } = new();
        public Dictionary<string, object> Parameters { get; set; } = new();
        public DateTime QueuedAt { get; set; }
    }

    public class PollingResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public List<int> QueuedReportIds { get; set; } = new();
        public DateTime CheckTime { get; set; }
    }
}