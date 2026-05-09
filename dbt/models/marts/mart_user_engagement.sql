-- Mart: user engagement — primary table for BI dashboards
-- One row per user per week, joining activity + sleep signals
-- Used for: retention analysis, engagement cohorts, churn prediction

with users as (
    select * from {{ ref('stg_users') }}
),

activity as (
    select * from {{ ref('int_user_activity') }}
),

sleep as (
    select * from {{ ref('int_sleep_metrics') }}
),

joined as (
    select
        a.user_id,
        a.event_week,
        u.registered_at,
        u.subscription_type,
        u.is_paying,
        u.age_group,
        u.country,
        u.device_model,

        -- Engagement signals
        a.active_days,
        a.sessions,
        a.total_events,
        a.syncs,
        a.sleep_views,
        a.activity_views,
        a.readiness_views,
        a.insights_opened,
        a.engagement_tier,

        -- Sleep quality
        s.avg_sleep_score,
        s.avg_sleep_hours,
        s.avg_readiness_score,
        s.days_with_data                               as days_with_health_data,

        -- Derived fields
        datediff('week', u.registered_at, a.event_week) as weeks_since_registration,
        case
            when datediff('week', u.registered_at, a.event_week) = 0 then 'Week 0'
            when datediff('week', u.registered_at, a.event_week) <= 3 then 'Onboarding'
            when datediff('week', u.registered_at, a.event_week) <= 12 then 'Early'
            else 'Established'
        end as lifecycle_stage

    from activity a
    left join users   u on a.user_id = u.user_id
    left join sleep   s on a.user_id = s.user_id
                       and a.event_week = s.metric_week
)

select * from joined
