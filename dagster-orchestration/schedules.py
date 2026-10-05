from dagster import ScheduleDefinition, define_asset_job

london_bicycles_pipeline_job = define_asset_job(
    name="london_bicycles_pipeline_job",
    selection="*"
)

daily_pipeline_schedule = ScheduleDefinition(
    name="daily_pipeline_schedule",
    job=london_bicycles_pipeline_job,
    cron_schedule="1 0 * * *",
    execution_timezone="Asia/Singapore"
)
