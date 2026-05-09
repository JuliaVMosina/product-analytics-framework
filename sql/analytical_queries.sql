-- ============================================================
-- Product Analytics Framework — Key Analytical Queries
-- Wearable Health Application
-- ============================================================

-- ── North Star Metric ────────────────────────────────────────
-- DAU/MAU ratio — measures product stickiness
-- Target: > 0.4 (benchmark for health apps)

with daily_active as (
    select event_date, count(distinct user_id) as dau
    from mart_user_engagement
    group by 1
),
monthly_active as (
    select
        date_trunc('month', event_week)::date as month,
        count(distinct user_id)               as mau
    from mart_user_engagement
    group by 1
)
select
    m.month,
    round(avg(d.dau), 0)                      as avg_dau,
    m.mau,
    round(avg(d.dau)::numeric / m.mau, 2)     as dau_mau_ratio
from monthly_active m
join daily_active d on date_trunc('month', d.event_date) = m.month
group by m.month, m.mau
order by 1;


-- ── Retention Cohort Analysis ────────────────────────────────
-- Weekly retention by registration cohort
-- Shows % of users still active N weeks after signup

with cohorts as (
    select
        user_id,
        date_trunc('week', registered_at)::date as cohort_week
    from mart_user_engagement
    group by 1, 2
),
activity as (
    select
        e.user_id,
        c.cohort_week,
        e.event_week,
        datediff('week', c.cohort_week, e.event_week) as weeks_since_signup
    from mart_user_engagement e
    join cohorts c on e.user_id = c.user_id
),
cohort_sizes as (
    select cohort_week, count(distinct user_id) as cohort_size
    from cohorts
    group by 1
)
select
    a.cohort_week,
    a.weeks_since_signup,
    count(distinct a.user_id)                                         as retained_users,
    cs.cohort_size,
    round(count(distinct a.user_id) * 100.0 / cs.cohort_size, 1)     as retention_pct
from activity a
join cohort_sizes cs on a.cohort_week = cs.cohort_week
where a.weeks_since_signup between 0 and 12
group by 1, 2, cs.cohort_size
order by 1, 2;


-- ── Onboarding Funnel ────────────────────────────────────────
-- Tracks users through activation steps in first 7 days

with first_week_events as (
    select e.user_id, e.event_name
    from stg_events e
    join stg_users u on e.user_id = u.user_id
    where e.occurred_at <= u.registered_at + interval '7 days'
),
funnel as (
    select
        count(distinct user_id)                                                   as step_0_registered,
        count(distinct case when event_name = 'ring_synced'      then user_id end) as step_1_synced,
        count(distinct case when event_name = 'sleep_viewed'     then user_id end) as step_2_sleep_viewed,
        count(distinct case when event_name = 'readiness_viewed' then user_id end) as step_3_readiness_viewed,
        count(distinct case when event_name = 'insight_opened'   then user_id end) as step_4_insight_opened
    from first_week_events
)
select 'Registered'       as step, step_0_registered  as users, 100.0                                                    as pct from funnel
union all
select 'Ring synced',        step_1_synced,       round(step_1_synced       * 100.0 / step_0_registered, 1) from funnel
union all
select 'Sleep viewed',       step_2_sleep_viewed,  round(step_2_sleep_viewed  * 100.0 / step_0_registered, 1) from funnel
union all
select 'Readiness viewed',   step_3_readiness_viewed, round(step_3_readiness_viewed * 100.0 / step_0_registered, 1) from funnel
union all
select 'Insight opened',     step_4_insight_opened, round(step_4_insight_opened * 100.0 / step_0_registered, 1) from funnel;


-- ── Feature Engagement by Tier ───────────────────────────────
-- Which features drive high engagement users?

select
    engagement_tier,
    round(avg(sleep_views), 1)        as avg_sleep_views,
    round(avg(activity_views), 1)     as avg_activity_views,
    round(avg(readiness_views), 1)    as avg_readiness_views,
    round(avg(insights_opened), 1)    as avg_insights_opened,
    round(avg(syncs), 1)              as avg_syncs,
    count(distinct user_id)           as user_count
from mart_user_engagement
group by 1
order by
    case engagement_tier when 'high' then 1 when 'medium' then 2 else 3 end;


-- ── Health Scores by Subscription Tier ──────────────────────

select
    subscription_type,
    sleep_tier,
    count(*)                          as days,
    round(avg(sleep_score), 1)        as avg_sleep_score,
    round(avg(readiness_score), 1)    as avg_readiness_score,
    round(avg(health_index), 1)       as avg_health_index
from mart_health_scores
group by 1, 2
order by 1, avg_sleep_score desc;


-- ── A/B Test Impact Analysis ─────────────────────────────────
-- Example: measure new onboarding flow impact on week-1 engagement

with experiment as (
    select
        user_id,
        max(case
            when event_name = 'experiment_assigned'
             and json_extract_path_text(properties, 'experiment_id') = 'new_onboarding_v2'
            then json_extract_path_text(properties, 'variant')
        end) as variant
    from stg_events
    group by 1
)
select
    ex.variant,
    count(distinct me.user_id)           as users,
    round(avg(me.active_days), 2)        as avg_active_days,
    round(avg(me.sessions), 2)           as avg_sessions,
    round(avg(me.insights_opened), 2)    as avg_insights_opened,
    round(avg(hs.avg_sleep_score), 1)    as avg_sleep_score
from experiment ex
join mart_user_engagement me on ex.user_id = me.user_id
                             and me.weeks_since_registration between 1 and 4
left join int_sleep_metrics hs on ex.user_id = hs.user_id
where ex.variant is not null
group by 1
order by 1;
