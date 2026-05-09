-- Intermediate model: user activity summary by week
-- Aggregates events into weekly engagement signals
--
-- North Star Metric: WIAU (Weekly Insight Active Users)
-- A user counts as "insight active" if they fired insight_view OR recommendation_click
-- at least once within the 7-day window. (Thesis §3.1.5)
--
-- Engagement depth = deep interaction events / sessions (Thesis §3.1.3, formula 3)
-- Deep interaction events: insight_view, recommendation_click, notification_click

with events as (
    select * from {{ ref('stg_events') }}
),

weekly as (
    select
        user_id,
        event_week,
        count(distinct event_date)                              as active_days,
        count(distinct session_id)                              as sessions,
        count(event_id)                                         as total_events,

        -- Health data views
        count(case when event_name = 'sleep_view'              then 1 end) as sleep_views,
        count(case when event_name = 'readiness_view'          then 1 end) as readiness_views,
        count(case when event_name = 'activity_view'           then 1 end) as activity_views,
        count(case when event_name = 'trend_view'              then 1 end) as trend_views,

        -- Deep analytical interaction (used for NSM and engagement depth)
        count(case when event_name = 'insight_view'            then 1 end) as insight_views,
        count(case when event_name = 'recommendation_click'    then 1 end) as recommendation_clicks,
        count(case when event_name = 'notification_click'      then 1 end) as notification_clicks,

        -- Subscription signals
        count(case when event_name = 'paywall_view'            then 1 end) as paywall_views,

        -- WIAU flag: insight_view OR recommendation_click at least once this week
        max(case when event_name in ('insight_view', 'recommendation_click')
                 then 1 else 0 end)                             as is_insight_active
    from events
    group by 1, 2
),

with_metrics as (
    select
        *,
        -- Engagement frequency (Thesis formula 2)
        round(active_days / 7.0, 3)                             as engagement_frequency,

        -- Engagement depth (Thesis formula 3)
        case when sessions > 0
             then round((insight_views + recommendation_clicks + notification_clicks)::numeric / sessions, 2)
             else 0
        end                                                     as engagement_depth,

        -- Engagement tier for segmentation
        case
            when active_days >= 5 then 'high'
            when active_days >= 2 then 'medium'
            else 'low'
        end                                                     as engagement_tier
    from weekly
)

select * from with_metrics
