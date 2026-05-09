-- Mart: Subscription retention (renewal rate)
-- Percentage of subscribers who renewed at least once
-- Thesis §4.1.3 (Listing 12): Result = 74.5%
-- Renewal = subscription_status = 'renewed'

with first_sub as (
    select
        user_id,
        min(subscription_start)                        as first_start
    from {{ ref('stg_subscriptions') }}
    group by 1
),

renewals as (
    select distinct user_id
    from {{ ref('stg_subscriptions') }}
    where subscription_status = 'renewed'
)

select
    count(distinct f.user_id)                          as total_subscribers,
    count(distinct r.user_id)                          as renewed_users,
    round(
        count(distinct r.user_id) * 100.0
        / nullif(count(distinct f.user_id), 0), 1
    )                                                  as subscription_retention_pct
from first_sub f
left join renewals r on f.user_id = r.user_id
