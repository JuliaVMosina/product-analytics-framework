-- Staging model: raw users from source system
-- One row per registered user

with source as (
    select * from {{ source('raw', 'users') }}
),

renamed as (
    select
        user_id,
        created_at::timestamp                          as registered_at,
        date(created_at)                               as registration_date,
        country,
        device_model,
        app_version,
        subscription_type,                             -- free / plus / lifetime
        case
            when subscription_type = 'free'     then false
            else true
        end                                            as is_paying,
        age_group,                                     -- 18-24 / 25-34 / 35-44 / 45+
        gender
    from source
    where user_id is not null
)

select * from renamed
