-- Staging model: raw product events
-- One row per user action in the app
-- Event naming convention: object_action (e.g. sleep_viewed, ring_synced)

with source as (
    select * from {{ source('raw', 'events') }}
),

renamed as (
    select
        event_id,
        user_id,
        event_name,
        event_timestamp::timestamp                     as occurred_at,
        date(event_timestamp)                          as event_date,
        date_trunc('week', event_timestamp)::date      as event_week,
        date_trunc('month', event_timestamp)::date     as event_month,
        session_id,
        platform,                                      -- ios / android
        app_version,
        properties                                     -- json blob of event metadata
    from source
    where event_id is not null
      and user_id  is not null
      and event_timestamp >= '2024-01-01'
)

select * from renamed
