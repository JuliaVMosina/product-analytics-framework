-- Staging model: subscription records
-- One row per subscription lifecycle entry
-- Tracks: start, renew, cancel, expired

with source as (
    select * from {{ source('raw', 'subscriptions') }}
),

renamed as (
    select
        subscription_id,
        user_id,
        subscription_start::date                       as subscription_start,
        subscription_end::date                         as subscription_end,
        subscription_status,                           -- active / renewed / cancelled / expired
        subscription_type,                             -- plus / lifetime
        payment_provider,

        -- Derived
        case when subscription_status = 'active' then true else false end as is_active,
        datediff('day', subscription_start::date, coalesce(subscription_end::date, current_date)) as subscription_days
    from source
    where subscription_id is not null
      and user_id          is not null
)

select * from renamed
