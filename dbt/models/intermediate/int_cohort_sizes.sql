-- Intermediate model: cohort sizes by registration week
-- Provides |C_0| (denominator) for retention formula: Retention_n = |A_n| / |C_0|
-- Thesis §3.1.2, formula 1

with cohorts as (
    select * from {{ ref('int_user_cohorts') }}
)

select
    cohort_week,
    count(distinct user_id)                            as cohort_size,
    count(distinct case when is_paying then user_id end) as paying_users,
    count(distinct case when activation_date is not null then user_id end) as activated_users,
    round(
        count(distinct case when activation_date is not null then user_id end) * 100.0
        / nullif(count(distinct user_id), 0), 1
    )                                                  as activation_rate_pct
from cohorts
group by 1
order by 1
