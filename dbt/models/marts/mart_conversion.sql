-- Mart: Subscription conversion metrics
-- Thesis §3.1.4, formula 5: Conversion_to_paid = subscription_start / paywall_view
-- Thesis §4.1.3 (Listing 11): Result = 19.6%

with users as (
    select user_id
    from {{ ref('stg_users') }}
),

subscriptions as (
    select distinct user_id
    from {{ ref('stg_subscriptions') }}
    where subscription_type != 'free'
      and subscription_status in ('active', 'renewed', 'cancelled', 'expired')
)

select
    count(distinct u.user_id)                          as total_users,
    count(distinct s.user_id)                          as paid_users,
    round(
        count(distinct s.user_id) * 100.0
        / nullif(count(distinct u.user_id), 0), 1
    )                                                  as conversion_to_paid_pct
from users u
left join subscriptions s on u.user_id = s.user_id
