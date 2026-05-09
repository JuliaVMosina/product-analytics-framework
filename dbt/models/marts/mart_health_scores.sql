-- Mart: daily health scores per user
-- Primary table for health trend dashboards
-- One row per user per day

with health as (
    select * from {{ ref('stg_health_metrics') }}
),

users as (
    select * from {{ ref('stg_users') }}
),

joined as (
    select
        h.user_id,
        h.metric_date,
        u.subscription_type,
        u.age_group,
        u.country,

        -- Scores
        h.sleep_score,
        h.activity_score,
        h.readiness_score,

        -- Composite health index (simple average)
        round((h.sleep_score + h.activity_score + h.readiness_score) / 3.0, 1) as health_index,

        -- Sleep detail
        round(h.total_sleep_minutes / 60.0, 1)         as sleep_hours,
        h.deep_sleep_minutes,
        h.rem_sleep_minutes,
        h.sleep_efficiency_pct,

        -- Activity detail
        h.steps,
        h.active_calories,
        h.inactive_hours,

        -- Biometrics
        h.resting_heart_rate,
        h.heart_rate_variability,
        h.body_temperature_deviation,

        -- Score tiers
        case
            when h.sleep_score >= 85 then 'Optimal'
            when h.sleep_score >= 70 then 'Good'
            when h.sleep_score >= 60 then 'Fair'
            else 'Pay attention'
        end as sleep_tier,

        case
            when h.readiness_score >= 85 then 'Optimal'
            when h.readiness_score >= 70 then 'Good'
            when h.readiness_score >= 60 then 'Fair'
            else 'Pay attention'
        end as readiness_tier

    from health h
    left join users u on h.user_id = u.user_id
)

select * from joined
