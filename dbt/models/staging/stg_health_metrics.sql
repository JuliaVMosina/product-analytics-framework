-- Staging model: daily health measurements from wearable device
-- One row per user per day

with source as (
    select * from {{ source('raw', 'health_metrics') }}
),

renamed as (
    select
        metric_id,
        user_id,
        metric_date::date                              as metric_date,

        -- Sleep
        sleep_score,                                   -- 0-100
        total_sleep_minutes,
        deep_sleep_minutes,
        rem_sleep_minutes,
        sleep_efficiency_pct,

        -- Activity
        activity_score,                                -- 0-100
        steps,
        active_calories,
        inactive_hours,

        -- Readiness
        readiness_score,                               -- 0-100
        resting_heart_rate,
        heart_rate_variability,
        body_temperature_deviation
    from source
    where metric_id is not null
      and user_id   is not null
)

select * from renamed
