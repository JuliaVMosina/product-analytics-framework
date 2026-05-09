-- Mart: Weekly Active Users (WAU)
-- One row per calendar week — users who had at least one session
-- Thesis §4.1.3 (Listing 9): AVG_WAU = 768.8

with sessions as (
    select * from {{ ref('stg_sessions') }}
)

select
    date_trunc('week', session_start)::date            as week,
    count(distinct user_id)                            as wau
from sessions
group by 1
order by 1
