-- Staging model: raw users from source system
-- One row per registered user

with source as (
    select * from {{ source('raw', 'users') }}
),

renamed as (
    select
        user_id,
        registration_date::date                        as registration_date,
        country,
        acquisition_source,
        platform,                                      -- ios / android
        device_model,
        app_version,
        subscription_type,                             -- free / plus / lifetime
        user_type,                                     -- casual / regular / power (Thesis §4)
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
