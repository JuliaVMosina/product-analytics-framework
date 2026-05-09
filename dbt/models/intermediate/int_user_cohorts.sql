-- Intermediate model: user cohort assignment
-- Assigns each user to a registration week cohort for cohort-based retention analysis
-- Thesis §3.1.2 — cohort = set of users sharing the same activation week (C_0)

with users as (
    select * from {{ ref('stg_users') }}
),

events as (
    select user_id, min(event_date) as first_active_date
    from {{ ref('stg_events') }}
    where event_name = 'onboarding_complete'
    group by 1
)

select
    u.user_id,
    u.registration_date,
    u.country,
    u.acquisition_source,
    u.platform,
    u.subscription_type,
    u.is_paying,
    u.user_type,
    u.age_group,
    date_trunc('week', u.registration_date)::date      as cohort_week,
    e.first_active_date                                as activation_date,
    datediff('day', u.registration_date, e.first_active_date) as days_to_activate
from users u
left join events e on u.user_id = e.user_id
