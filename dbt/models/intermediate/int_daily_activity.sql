-- Intermediate model: daily user activity
-- One row per user per day — used for retention and DAU/WAU calculations
-- Derived from sessions_clean: a user is "active" if they had at least one session
-- Thesis §4.1.2 (Listing 7)

with sessions as (
    select * from {{ ref('stg_sessions') }}
)

select
    user_id,
    date(session_start)                                as activity_date,
    date_trunc('week', session_start)::date            as activity_week,
    count(*)                                           as sessions_count,
    sum(session_duration)                              as total_session_minutes,
    min(session_start)                                 as first_session_of_day,
    max(session_end)                                   as last_session_of_day
from sessions
group by 1, 2, 3
