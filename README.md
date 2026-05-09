# Product Analytics Framework — Wearable Health Application

Bachelor's Thesis · Metropolia University of Applied Sciences · April 2026

**Title:** Design and Evaluation of a Product Analytics Framework for a Wearable Health Tracking Application  
**Degree:** Bachelor of Engineering, Information and Communication Technology  
**Author:** Julia Mosina

---

## Overview

This repository contains the practical implementation of a product analytics framework designed for a mobile application connected to a wearable health device. The framework covers the full analytics stack — from event schema design to dbt data models and SQL-based metric calculation.

The goal is to support data-driven product decisions through structured event tracking, clearly defined metrics, and a layered data architecture.

---

## North Star Metric

**WIAU — Weekly Insight Active Users**

> Number of unique users who performed `insight_view` at least once within a 7-day period.

This metric was chosen because it captures active analytical engagement with the product — not passive data generation from the wearable device. DAU or app opens would count users who only opened the app; WIAU ensures the user actually received value from their health analytics.

Supporting metrics: activation rate · D7/D30 retention · Value Engagement Ratio · subscription conversion

---

## Event Taxonomy

Events follow the `object_action` naming convention and are grouped by lifecycle stage:

| Group | Events |
|---|---|
| Launch & activation | `app_install` · `app_open` · `app_first_open` · `onboarding_complete` · `device_connected` |
| Health data views | `sleep_view` · `readiness_view` · `activity_view` · `trend_view` |
| Analytical interaction | `insight_view` · `recommendation_click` · `notification_click` |
| Subscription | `paywall_view` · `subscription_start` · `subscription_renew` · `subscription_cancel` · `subscription_expired` |

**User journey:** User → Activation (onboarding) → Engagement (core interaction) → Monetization (subscription)

---

## Metric Definitions

**Activation** — user is activated if, within 24h of install:
- `onboarding_complete` is fired
- at least one analytics view (`sleep_view` or `insight_view`) is recorded

**Retention** (formula from §3.1.2):
```
Retention_n = |A_n| / |C_0|
```
- Day 0 = `onboarding_complete`
- Active = `app_open`, `sleep_view`, `readiness_view`, or `insight_view`

**Engagement frequency** (§3.1.3):
```
Engagement_frequency = active_days / total_days_in_period
```

**Engagement depth** (§3.1.3):
```
Engagement_depth = deep_interaction_events / sessions
```
Session boundary: >30 min inactivity. Deep events: `insight_view`, `recommendation_click`, `notification_click`.

**Value Engagement Ratio** (formula 12):
```
Value_Engagement_Ratio = WIAU / WAU
```
Result: 90.1% — more than 90% of active users interact with personalized insights.

**Conversion to paid** (§3.1.4):
```
Conversion_to_paid = subscription_start / total_users  → 19.6%
Subscription_retention = renewed / total_subscribers   → 74.5%
```

---

## Three Funnels

| Funnel | Stages | Purpose |
|---|---|---|
| Activation | `app_install` → `app_first_open` → `onboarding_complete` → `device_connected` → `insight_view` | Measures first meaningful experience |
| Engagement | `app_first_open` → `sleep_view` → `insight_view` → `recommendation_click` → repeated WIAU | Tracks depth of usage, tied to NSM |
| Monetization | `insight_view` → `paywall_view` → `subscription_start` → `subscription_renew` | Free-to-paid conversion |

---

## Key Metric Results (Thesis Table 1)

| Metric | Value | Interpretation |
|---|---|---|
| AVG_WAU | 768.8 | Weekly active users |
| AVG_WIAU | 692.4 | Users reaching analytical value |
| Value Engagement Ratio | 90.1% | Share of active users reaching value |
| Conversion to Paid | 19.6% | Subscription conversion rate |
| Subscription Retention | 74.5% | Renewal rate |
| Week 1 Retention | 95.5% | Early retention performance |

---

## Data Architecture

```
Wearable Device + Mobile App
          │
          ▼
  Raw Data Layer
  (users · events · sessions · subscriptions · health_metrics · feature_usage)
          │
          ▼
  dbt Staging Layer        ← type casting · renaming · filtering
          │
          ▼
  dbt Intermediate Layer   ← cohorts · daily activity · retention base · WIAU flag
          │
          ▼
  dbt Marts                ← WAU · WIAU · conversion · subscription retention · cohort retention
          │
          ▼
  BI Dashboards / Analytics
```

---

## Data Generation Parameters (Thesis §4)

```
python/generate_data.py
```

| Parameter | Value |
|---|---|
| Users | 1000 |
| Observation period | 120 days per user |
| Behavioral types | casual (50%) · regular (35%) · power (15%) |
| Subscription model | monthly with renewal |
| Health metrics | sleep · activity · readiness (daily) |

---

## Data Model (ER Diagram)

Core tables (§3.2.3):

| Table | Key fields |
|---|---|
| `users` | user_id · registration_date · country · acquisition_source · platform · user_type |
| `events` | event_id · user_id · session_id · event_name · event_timestamp · event_properties |
| `sessions` | session_id · user_id · session_start · session_end · session_duration |
| `subscriptions` | subscription_id · user_id · subscription_start · subscription_end · subscription_status · subscription_type |
| `health_metrics` | metric_id · user_id · metric_date · sleep_score · activity_score · readiness_score |
| `feature_usage` | feature_usage_id · user_id · feature_name · used_at · session_duration_seconds |

---

## dbt Models

### Staging
| Model | Description |
|---|---|
| `stg_users` | Typed + renamed users, `is_paying` flag, `user_type` (casual/regular/power) |
| `stg_events` | Typed events with full event taxonomy |
| `stg_sessions` | Cleaned sessions with `session_duration`; filters invalid intervals |
| `stg_subscriptions` | Subscription lifecycle, `is_active` flag, `subscription_status` |
| `stg_health_metrics` | Daily wearable measurements |
| `stg_feature_usage` | Feature interaction events |

### Intermediate
| Model | Description |
|---|---|
| `int_user_cohorts` | Cohort assignment by registration week · activation date |
| `int_daily_activity` | Daily session aggregates per user · basis for DAU/WAU |
| `int_cohort_sizes` | Cohort sizes `|C_0|` for retention denominator |
| `int_retention_base` | User × day_n retention dataset (joined cohorts + daily activity) |
| `int_user_activity` | Weekly event aggregates · WIAU flag · engagement_frequency · engagement_depth |
| `int_sleep_metrics` | Weekly sleep quality aggregates |

### Marts
| Model | Grain | Use |
|---|---|---|
| `mart_wau` | Week | Weekly Active Users baseline |
| `mart_wiau` | Week | North Star Metric — Weekly Insight Active Users |
| `mart_conversion` | All-time | Subscription conversion rate (19.6%) |
| `mart_subscription_retention` | All-time | Renewal rate (74.5%) |
| `mart_retention_summary` | Cohort × Day | D1/D7/D14/D30 retention by cohort |
| `mart_user_engagement` | User × Week | Full engagement profile for BI dashboards |
| `mart_health_scores` | User × Day | Health trend dashboards |

---

## dbt Tests

All primary keys: `not_null` + `unique`  
Categorical fields: `accepted_values` (subscription_type, subscription_status, user_type, event_name, platform)  
Cross-table: `relationships` (subscriptions → users, events → users)

Test files: `tests/users.yml` · `tests/subscriptions.yml` · `tests/events.yml`

---

## dbt Extras

- `packages.yml` — dbt_utils dependency
- `macros/metric_calculations.sql` — reusable macros: `safe_divide`, `retention_rate`, `is_insight_active`, `engagement_tier`
- `snapshots/subscriptions_snapshot.sql` — tracks subscription status changes over time

---

## SQL Queries

`sql/analytical_queries.sql` implements:
- WIAU trend (North Star Metric)
- Activation funnel (5 stages)
- Engagement funnel (5 stages)
- Monetization funnel (4 stages)
- Day-1 / Day-7 / Day-30 retention (cohort formula from §3.1.2)
- Engagement tier vs. subscription conversion (§4.3.3)
- Subscription metrics: conversion to paid · churn rate · subscription retention

---

## Running the Data Generator

```bash
cd python
pip install pandas numpy
python generate_data.py
# → data/raw_users.csv         (1000 users)
# → data/raw_events.csv        (events per taxonomy)
# → data/raw_sessions.csv      (session records)
# → data/raw_subscriptions.csv (subscription lifecycle)
# → data/raw_health_metrics.csv
# → data/raw_feature_usage.csv
```

---

## Repository Structure

```
product-analytics-framework/
├── README.md
├── dbt/
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── models/
│   │   ├── staging/
│   │   │   ├── stg_users.sql
│   │   │   ├── stg_events.sql           ← full event taxonomy documented
│   │   │   ├── stg_sessions.sql         ← session_duration, invalid interval filter
│   │   │   ├── stg_subscriptions.sql    ← subscription_status lifecycle
│   │   │   ├── stg_health_metrics.sql
│   │   │   ├── stg_feature_usage.sql
│   │   │   └── schema.yml
│   │   ├── intermediate/
│   │   │   ├── int_user_cohorts.sql     ← cohort assignment by reg week
│   │   │   ├── int_daily_activity.sql   ← DAU basis
│   │   │   ├── int_cohort_sizes.sql     ← |C_0| for retention formula
│   │   │   ├── int_retention_base.sql   ← user × day_n dataset
│   │   │   ├── int_user_activity.sql    ← WIAU flag + engagement metrics
│   │   │   └── int_sleep_metrics.sql
│   │   └── marts/
│   │       ├── mart_wau.sql             ← WAU weekly
│   │       ├── mart_wiau.sql            ← NSM: WIAU weekly
│   │       ├── mart_conversion.sql      ← subscription conversion
│   │       ├── mart_subscription_retention.sql ← renewal rate
│   │       ├── mart_retention_summary.sql      ← cohort retention D1/D7/D14/D30
│   │       ├── mart_user_engagement.sql        ← BI dashboard table
│   │       ├── mart_health_scores.sql
│   │       └── schema.yml
│   ├── tests/
│   │   ├── users.yml
│   │   ├── subscriptions.yml
│   │   └── events.yml
│   ├── macros/
│   │   └── metric_calculations.sql      ← safe_divide, retention_rate, engagement_tier
│   └── snapshots/
│       └── subscriptions_snapshot.sql   ← subscription state history
├── sql/
│   └── analytical_queries.sql           ← NSM · 3 funnels · retention · conversion
├── python/
│   └── generate_data.py                 ← 1000 users · 120 days · 3 behavioral types
├── data/                                ← generated CSVs (gitignored)
└── Design and evaluation of a product analytics framework
    for a wearable health tracking application.pdf
```

---

## About

**Julia Mosina** — BI & Data Analyst  
Metropolia University of Applied Sciences, Degree Programme in Information and Communication Technology  
[LinkedIn](https://www.linkedin.com/in/julia-mosina) · Helsinki, Finland · Open to opportunities in Finland and EU
