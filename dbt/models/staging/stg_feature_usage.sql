-- Staging model: feature usage events
-- One row per feature interaction, used to analyze feature adoption patterns
-- Feature names: sleep_insights, readiness_score, activity_trends,
--                weekly_summary, health_alerts, goal_tracking

with source as (
    select * from {{ source('raw', 'feature_usage') }}
),

renamed as (
    select
        feature_usage_id,
        user_id,
        feature_name,
        used_at::timestamp                             as used_at,
        date(used_at)                                  as usage_date,
        date_trunc('week', used_at)::date              as usage_week,
        session_duration_seconds
    from source
    where feature_usage_id is not null
      and user_id           is not null
      and feature_name      is not null
)

select * from renamed
