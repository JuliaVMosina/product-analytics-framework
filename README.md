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

> Number of unique users who performed `insight_view` or `recommendation_click` at least once within a 7-day period.

This metric was chosen because it captures active analytical engagement with the product — not passive data generation from the wearable device. DAU or app opens would count users who only opened the app; WIAU ensures the user actually received value from their health analytics.

Supporting metrics: activation rate · D7/D30 retention · engagement depth · subscription conversion

---

## Event Taxonomy

Events follow the `object_action` naming convention and are grouped by lifecycle stage:

| Group | Events |
|---|---|
| Launch & activation | `app_install` · `app_open` · `app_first_open` · `onboarding_complete` |
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

**Conversion to paid** (§3.1.4):
```
Conversion_to_paid = subscription_start / paywall_view
Churn_rate = subscription_cancel / active_subscribers
```

---

## Three Funnels

| Funnel | Stages | Purpose |
|---|---|---|
| Activation | `app_install` → `app_first_open` → `onboarding_complete` → `device_connected` → `insight_view` | Measures first meaningful experience |
| Engagement | `app_first_open` → `sleep_view` → `insight_view` → `recommendation_click` → repeated WIAU | Tracks depth of usage, tied to NSM |
| Monetization | `insight_view` → `paywall_view` → `subscription_start` → `subscription_renew` | Free-to-paid conversion |

---

## Data Architecture

```
Wearable Device + Mobile App
          │
          ▼
  Raw Data Layer
  (users · events · sessions · subscriptions · health_metrics)
          │
          ▼
  dbt Staging Layer        ← type casting · renaming · filtering
          │
          ▼
  dbt Intermediate Layer   ← WIAU flag · engagement metrics · weekly aggregates
          │
          ▼
  dbt Marts                ← BI-ready tables (user × week, user × day)
          │
          ▼
  BI Dashboards
```

---

## Data Model (ER Diagram)

Core tables (§3.2.3):

| Table | Key fields |
|---|---|
| `users` | user_id · registration_date · country · acquisition_source · platform |
| `events` | event_id · user_id · session_id · event_name · event_timestamp · event_properties |
| `sessions` | session_id · user_id · session_start · session_end · session_duration |
| `subscriptions` | subscription_id · user_id · start_date · end_date · status · subscription_type |
| `health_metrics` | metric_id · user_id · device_id · metric_type · metric_value · metric_date |

---

## dbt Models

### Staging
| Model | Description |
|---|---|
| `stg_users` | Typed + renamed users, `is_paying` flag |
| `stg_events` | Typed events with event taxonomy comments |
| `stg_subscriptions` | Subscription lifecycle, `is_active` flag |
| `stg_health_metrics` | Daily wearable measurements |

### Intermediate
| Model | Description |
|---|---|
| `int_user_activity` | Weekly event aggregates · WIAU flag · engagement_frequency · engagement_depth |
| `int_sleep_metrics` | Weekly sleep quality aggregates |

### Marts
| Model | Grain | Use |
|---|---|---|
| `mart_user_engagement` | User × Week | Retention · cohort analysis · NSM tracking |
| `mart_health_scores` | User × Day | Health trend dashboards |

---

## dbt Tests

All primary keys: `not_null` + `unique`  
Categorical fields: `accepted_values` (subscription_type, engagement_tier, sleep_tier)  
Cross-table: `relationships` between fact and dimension tables

---

## SQL Queries

`sql/analytical_queries.sql` implements:
- WIAU trend (North Star Metric)
- Activation funnel (5 stages)
- Engagement funnel (5 stages)
- Monetization funnel (4 stages)
- Day-1 / Day-7 / Day-30 retention (cohort formula from §3.1.2)
- Engagement tier vs. subscription conversion (§4.3.3 regression analysis)

---

## Running the Data Generator

```bash
cd python
pip install pandas numpy
python generate_data.py
# → data/raw_users.csv, raw_events.csv, raw_health_metrics.csv
```

---

## Repository Structure

```
product-analytics-framework/
├── README.md
├── dbt/
│   ├── dbt_project.yml
│   └── models/
│       ├── staging/
│       │   ├── stg_users.sql
│       │   ├── stg_events.sql           ← event taxonomy documented
│       │   ├── stg_subscriptions.sql
│       │   ├── stg_health_metrics.sql
│       │   └── schema.yml
│       ├── intermediate/
│       │   ├── int_user_activity.sql    ← WIAU flag + engagement metrics
│       │   └── int_sleep_metrics.sql
│       └── marts/
│           ├── mart_user_engagement.sql
│           ├── mart_health_scores.sql
│           └── schema.yml
├── sql/
│   └── analytical_queries.sql           ← NSM · 3 funnels · retention · conversion
├── python/
│   └── generate_data.py
└── Design and evaluation of a product analytics framework
    for a wearable health tracking application.pdf
```

---

## About

**Julia Mosina** — BI & Data Analyst  
Metropolia University of Applied Sciences, Degree Programme in Information and Communication Technology  
[LinkedIn](https://www.linkedin.com/in/julia-mosina) · Helsinki, Finland · Open to opportunities in Finland and EU
