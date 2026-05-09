-- Mart: Weekly Insight Active Users (WIAU) — North Star Metric
-- One row per calendar week — users who fired insight_view in that week
-- Thesis §3.1.5, formula 10; §4.1.3 (Listing 10): AVG_WIAU = 692.4
--
-- Value Engagement Ratio = WIAU / WAU = 90.1% (Thesis formula 12)

with insight_events as (
    select
        user_id,
        event_timestamp,
        date(event_timestamp)                          as event_date
    from {{ ref('stg_events') }}
    where event_name = 'insight_view'
),

wau as (
    select * from {{ ref('mart_wau') }}
)

select
    date_trunc('week', event_timestamp)::date          as week,
    count(distinct user_id)                            as wiau
from insight_events
group by 1
order by 1
