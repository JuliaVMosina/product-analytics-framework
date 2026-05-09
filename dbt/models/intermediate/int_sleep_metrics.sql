-- Intermediate model: weekly sleep quality aggregates per user

with health as (
    select * from {{ ref('stg_health_metrics') }}
),

weekly as (
    select
        user_id,
        date_trunc('week', metric_date)::date          as metric_week,
        round(avg(sleep_score), 1)                     as avg_sleep_score,
        round(avg(total_sleep_minutes) / 60.0, 1)      as avg_sleep_hours,
        round(avg(deep_sleep_minutes), 0)              as avg_deep_sleep_min,
        round(avg(rem_sleep_minutes), 0)               as avg_rem_sleep_min,
        round(avg(sleep_efficiency_pct), 1)            as avg_sleep_efficiency,
        round(avg(readiness_score), 1)                 as avg_readiness_score,
        round(avg(resting_heart_rate), 0)              as avg_rhr,
        count(metric_date)                             as days_with_data
    from health
    group by 1, 2
)

select * from weekly
