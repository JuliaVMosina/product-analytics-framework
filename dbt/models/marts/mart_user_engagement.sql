-- Mart: user engagement — primary BI table for retention and cohort analysis
-- One row per user per week, joining activity + sleep signals
-- Used for: retention analysis, engagement cohorts, NSM tracking

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
        u.registration_date,
        u.subscription_type,
        u.is_paying,
        u.age_group,
        u.country,
        u.user_type,

        -- Engagement signals
        a.active_days,
        a.sessions,
        a.total_events,
        a.sleep_views,
        a.readiness_views,
        a.activity_views,
        a.trend_views,
        a.insight_views,
        a.recommendation_clicks,
        a.notification_clicks,
        a.paywall_views,
        a.is_insight_active,
        a.engagement_frequency,
        a.engagement_depth,
        a.engagement_tier,

        -- Sleep quality
        s.avg_sleep_score,
        s.avg_sleep_hours,
        s.avg_readiness_score,
        s.days_with_data                               as days_with_health_data,

        -- Lifecycle stage
        datediff('week', u.registration_date::date, a.event_week) as weeks_since_registration

    from activity a
    left join users u on a.user_id = u.user_id
    left join sleep s on a.user_id = s.user_id
                     and a.event_week = s.metric_week
)

select * from joined
