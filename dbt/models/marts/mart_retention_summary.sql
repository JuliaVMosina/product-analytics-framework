-- Mart: Cohort-based retention summary
-- One row per cohort_week × day_n — implements Retention_n = |A_n| / |C_0|
-- Thesis §3.1.2, formula 1; §4.1.3: Week 1 retention = 95.5%

with retention_base as (
    select * from {{ ref('int_retention_base') }}
),

cohort_sizes as (
    select * from {{ ref('int_cohort_sizes') }}
)

select
    r.cohort_week,
    cs.cohort_size,
    r.day_n,
    count(distinct r.user_id)                          as retained_users,
    round(
        count(distinct r.user_id) * 100.0
        / nullif(cs.cohort_size, 0), 1
    )                                                  as retention_pct
from retention_base r
join cohort_sizes cs on r.cohort_week = cs.cohort_week
where r.day_n in (1, 7, 14, 30)
group by 1, 2, 3
order by 1, 3
