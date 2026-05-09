-- ============================================================
-- Product Analytics Framework — Key Analytical Queries
-- Wearable Health Application
-- Julia Mosina — Bachelor's Thesis, Metropolia UAS 2026
-- ============================================================

-- ── North Star Metric: WIAU ──────────────────────────────────
-- Weekly Insight Active Users (Thesis §3.1.5, formula 10)
-- Users who performed insight_view OR recommendation_click
-- at least once within a 7-day period.
-- This reflects active analytical engagement, not passive app opening.

select
    event_week,
    count(distinct case
        when event_name in ('insight_view', 'recommendation_click')
        then user_id
    end)                                          as wiau,
    count(distinct user_id)                       as wau,
    round(
        count(distinct case
            when event_name in ('insight_view', 'recommendation_click')
            then user_id
        end) * 100.0 / nullif(count(distinct user_id), 0),
    1)                                            as wiau_pct_of_wau
from stg_events
group by 1
order by 1;


-- ── Activation Funnel ────────────────────────────────────────
-- Thesis §3.3.1 — 5 stages, measures first meaningful user experience
-- Activation = onboarding_complete + at least one analytics view within 24h

with funnel as (
    select
        count(distinct case when event_name = 'app_install'         then user_id end) as s1_install,
        count(distinct case when event_name = 'app_first_open'      then user_id end) as s2_first_open,
        count(distinct case when event_name = 'onboarding_complete' then user_id end) as s3_onboarding,
        count(distinct case when event_name = 'device_connected'    then user_id end) as s4_device,
        count(distinct case when event_name in ('first_sleep_view', 'insight_view')
                            then user_id end)                                          as s5_first_insight
    from stg_events
)
select 'app_install'         as stage, s1_install    as users, 100.0                                      as pct from funnel
union all
select 'app_first_open',                s2_first_open, round(s2_first_open * 100.0 / nullif(s1_install, 0), 1)    from funnel
union all
select 'onboarding_complete',           s3_onboarding, round(s3_onboarding * 100.0 / nullif(s1_install, 0), 1)   from funnel
union all
select 'device_connected',              s4_device,     round(s4_device     * 100.0 / nullif(s1_install, 0), 1)    from funnel
union all
select 'first_insight_view',            s5_first_insight, round(s5_first_insight * 100.0 / nullif(s1_install, 0), 1) from funnel;


-- ── Engagement Funnel ────────────────────────────────────────
-- Thesis §3.3.2 — measures movement from basic to deep usage
-- Connected to NSM: stage 5 (repeated WIAU) = North Star achieved

with user_events as (
    select user_id, event_name, event_week
    from stg_events
),
funnel as (
    select
        count(distinct case when event_name = 'app_first_open'      then user_id end) as s1_open,
        count(distinct case when event_name = 'sleep_view'          then user_id end) as s2_sleep,
        count(distinct case when event_name = 'insight_view'        then user_id end) as s3_insight,
        count(distinct case when event_name = 'recommendation_click' then user_id end) as s4_recommendation,
        -- Stage 5: repeated insight interaction (WIAU in 2+ consecutive weeks)
        count(distinct user_id) as s5_repeated
    from user_events
)
select 'app_first_open'       as stage, s1_open,        100.0                                             as pct from funnel
union all
select 'sleep_view',                    s2_sleep,        round(s2_sleep        * 100.0 / nullif(s1_open, 0), 1) from funnel
union all
select 'insight_view',                  s3_insight,      round(s3_insight      * 100.0 / nullif(s1_open, 0), 1) from funnel
union all
select 'recommendation_click',          s4_recommendation, round(s4_recommendation * 100.0 / nullif(s1_open, 0), 1) from funnel;


-- ── Monetization Funnel ──────────────────────────────────────
-- Thesis §3.3.3 — tracks free-to-paid conversion
-- Conversion_to_paid = subscription_start / paywall_view (Thesis formula 5)

with funnel as (
    select
        count(distinct case when event_name = 'insight_view'        then user_id end) as s1_insight,
        count(distinct case when event_name = 'paywall_view'        then user_id end) as s2_paywall,
        count(distinct case when event_name = 'subscription_start'  then user_id end) as s3_start,
        count(distinct case when event_name = 'subscription_renew'  then user_id end) as s4_renew
    from stg_events
)
select 'insight_view'        as stage, s1_insight, 100.0                                                   as pct from funnel
union all
select 'paywall_view',                 s2_paywall,  round(s2_paywall * 100.0 / nullif(s1_insight, 0), 1)   from funnel
union all
select 'subscription_start',           s3_start,    round(s3_start   * 100.0 / nullif(s2_paywall, 0), 1)   from funnel
union all
select 'subscription_renew',           s4_renew,    round(s4_renew   * 100.0 / nullif(s3_start, 0), 1)     from funnel;


-- ── Day-N Retention ──────────────────────────────────────────
-- Thesis §3.1.2 — formula 1: Retention_n = |A_n| / |C_0|
-- Day 0 = onboarding_complete
-- Active = any of: app_open, sleep_view, readiness_view, insight_view

with day0 as (
    select user_id, min(event_date) as activation_date
    from stg_events
    where event_name = 'onboarding_complete'
    group by 1
),
active_days as (
    select e.user_id, e.event_date
    from stg_events e
    where event_name in ('app_open', 'sleep_view', 'readiness_view', 'insight_view')
)
select
    datediff('day', d.activation_date, a.event_date) as day_n,
    count(distinct a.user_id)                          as retained_users,
    count(distinct d.user_id)                          as cohort_size,
    round(count(distinct a.user_id) * 100.0 / count(distinct d.user_id), 1) as retention_pct
from day0 d
left join active_days a on d.user_id = a.user_id
where datediff('day', d.activation_date, a.event_date) in (1, 7, 14, 30)
group by 1
order by 1;


-- ── Engagement vs Subscription Probability ────────────────────
-- Thesis §4.3.3 — regression analysis: impact of engagement on payment
-- Shows whether high-engagement users convert more

select
    u.engagement_tier,
    count(distinct u.user_id)                          as users,
    round(avg(u.engagement_frequency), 3)              as avg_engagement_freq,
    round(avg(u.engagement_depth), 2)                  as avg_engagement_depth,
    round(avg(u.insight_views), 1)                     as avg_insight_views,
    sum(case when us.subscription_type != 'free' then 1 else 0 end) as paid_users,
    round(
        sum(case when us.subscription_type != 'free' then 1 else 0 end) * 100.0
        / nullif(count(distinct u.user_id), 0), 1
    )                                                  as conversion_rate_pct
from mart_user_engagement u
join stg_users us on u.user_id = us.user_id
group by 1
order by case u.engagement_tier when 'high' then 1 when 'medium' then 2 else 3 end;


-- ── Subscription Metrics ─────────────────────────────────────
-- Thesis §3.1.4 — monetization formulas 5-9

-- Conversion to paid (formula 5)
select
    round(
        count(distinct case when event_name = 'subscription_start' then user_id end) * 100.0
        / nullif(count(distinct case when event_name = 'paywall_view' then user_id end), 0),
    1) as conversion_to_paid_pct,

-- Subscription churn rate (formula 7)
    round(
        count(distinct case when event_name = 'subscription_cancel' then user_id end) * 100.0
        / nullif(count(distinct case when event_name = 'subscription_start' then user_id end), 0),
    1) as churn_rate_pct

from stg_events;
