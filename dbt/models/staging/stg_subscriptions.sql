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
        start_date::date                               as start_date,
        end_date::date                                 as end_date,
        status,                                        -- active / cancelled / expired
        subscription_type,                             -- plus / lifetime
        payment_provider,

        -- Derived
        case when status = 'active' then true else false end as is_active,
        datediff('day', start_date, coalesce(end_date, current_date)) as subscription_days
    from source
    where subscription_id is not null
      and user_id          is not null
)

select * from renamed
