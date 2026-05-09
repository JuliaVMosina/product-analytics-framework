-- Staging model: raw session records
-- One row per user session (group of events within a 30-min inactivity window)
-- Calculates session_duration; filters sessions with invalid time intervals

with source as (
    select * from {{ source('raw', 'sessions') }}
),

renamed as (
    select
        session_id,
        user_id,
        session_start::timestamp                       as session_start,
        session_end::timestamp                         as session_end,
        datediff('minute', session_start, session_end) as session_duration
    from source
    where session_id  is not null
      and user_id     is not null
      and session_end > session_start
)

select * from renamed
