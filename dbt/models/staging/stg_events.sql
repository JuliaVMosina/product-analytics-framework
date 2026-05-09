-- Staging model: raw product events
-- One row per user action in the app
--
-- Event taxonomy (from framework design):
--   Launch & activation:  app_install, app_open, app_first_open, onboarding_complete
--   Health data views:    sleep_view, readiness_view, activity_view, trend_view
--   Analytical interaction: insight_view, recommendation_click, notification_click
--   Subscription:         paywall_view, subscription_start, subscription_renew,
--                         subscription_cancel, subscription_expired
--
-- Session boundary: events separated by > 30 min of inactivity start a new session.

with source as (
    select * from {{ source('raw', 'events') }}
),

renamed as (
    select
        event_id,
        user_id,
        session_id,
        event_name,
        event_timestamp::timestamp                     as occurred_at,
        date(event_timestamp)                          as event_date,
        date_trunc('week', event_timestamp)::date      as event_week,
        date_trunc('month', event_timestamp)::date     as event_month,
        event_properties,                              -- JSON blob
        device_type,
        app_version,
        platform                                       -- ios / android
    from source
    where event_id        is not null
      and user_id         is not null
      and event_timestamp >= '2024-01-01'
)

select * from renamed
