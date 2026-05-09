-- Intermediate model: user activity summary by week
-- Aggregates events into weekly engagement signals

with events as (
    select * from {{ ref('stg_events') }}
),

weekly as (
    select
        user_id,
        event_week,
        count(distinct event_date)                     as active_days,
        count(distinct session_id)                     as sessions,
        count(event_id)                                as total_events,
        count(case when event_name = 'ring_synced'        then 1 end) as syncs,
        count(case when event_name = 'sleep_viewed'       then 1 end) as sleep_views,
        count(case when event_name = 'activity_viewed'    then 1 end) as activity_views,
        count(case when event_name = 'readiness_viewed'   then 1 end) as readiness_views,
        count(case when event_name = 'insight_opened'     then 1 end) as insights_opened
    from events
    group by 1, 2
),

with_engagement_tier as (
    select
        *,
        case
            when active_days >= 5 then 'high'
            when active_days >= 2 then 'medium'
            else 'low'
        end as engagement_tier
    from weekly
)

select * from with_engagement_tier
