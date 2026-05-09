-- Intermediate model: retention calculation base
-- Joins cohort assignments with daily activity to measure day-N retention
-- Implements: Retention_n = |A_n| / |C_0| (Thesis §3.1.2, formula 1)
-- Day 0 = onboarding_complete; active = any session in day.

with cohorts as (
    select user_id, cohort_week, activation_date
    from {{ ref('int_user_cohorts') }}
    where activation_date is not null
),

daily as (
    select user_id, activity_date
    from {{ ref('int_daily_activity') }}
)

select
    c.user_id,
    c.cohort_week,
    c.activation_date,
    d.activity_date,
    datediff('day', c.activation_date, d.activity_date) as day_n
from cohorts c
left join daily d on c.user_id = d.user_id
where datediff('day', c.activation_date, d.activity_date) >= 0
