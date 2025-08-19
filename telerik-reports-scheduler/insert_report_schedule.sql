INSERT INTO reports_scheduler (
    report_id,
    param_id,
    app_id,
    next_run_day,
    requestor,
    next_run_date_time,
    last_run_date_time,
    auto_sched,
    transdate
) VALUES (
    123,                          -- report_id: The ID of the report to run
    456,                          -- param_id: The ID of the report parameters
    789,                          -- app_id: The ID of the application
    'Mon',                        -- next_run_day: The day of the week for the next run
    'test_user',                  -- requestor: The user who requested the report
    NOW() - INTERVAL '1 minute',  -- next_run_date_time: Set to a time in the past
    NULL,                         -- last_run_date_time: Can be NULL for the first run
    'Y',                          -- auto_sched: Must be 'Y' to be picked up by the scheduler
    NOW()                         -- transdate: The date the record was created
);
