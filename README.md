# Product Analytics Framework — Wearable Health Application

Bachelor's Thesis Project · Metropolia University of Applied Sciences · 2026

**Thesis title:** Design and Evaluation of a Product Analytics Framework for a Wearable Health Tracking Application

---

## Overview

This repository contains a practical product analytics framework built for a wearable health application.
The framework covers the full analytics stack — from raw event data to BI-ready data marts — using
a modern analytics engineering approach with dbt, SQL, and Python.

The data architecture and metrics are modeled on real-world product analytics setups used in
digital health companies.

---

## Architecture

```
Wearable Device
      │
      ▼
Raw Data Sources (users · events · health_metrics)
      │
      ▼
dbt Staging Layer      ← type casting, renaming, basic filtering
      │
      ▼
dbt Intermediate Layer ← business logic, aggregations, joins
      │
      ▼
dbt Marts              ← BI-ready tables (one row per user per week / day)
      │
      ▼
BI Dashboard           ← Tableau / Power BI
```

---

## Data Model

### Staging
| Model | Description |
|---|---|
| `stg_users` | One row per user — typed, renamed, is_paying flag added |
| `stg_events` | One row per app event — typed, filtered, week/month added |
| `stg_health_metrics` | One row per user per day — wearable measurements |

### Intermediate
| Model | Description |
|---|---|
| `int_user_activity` | Weekly event aggregates per user + engagement_tier |
| `int_sleep_metrics` | Weekly sleep quality aggregates per user |

### Marts
| Model | Grain | Primary use |
|---|---|---|
| `mart_user_engagement` | User × Week | Retention, cohort analysis, churn signals |
| `mart_health_scores` | User × Day | Health trend dashboards, score distributions |

---

## Key Metrics Defined

**North Star:** DAU/MAU ratio (product stickiness, target > 0.4)

**Activation:**
- Ring sync rate in first 7 days
- Onboarding funnel completion (5 steps)

**Engagement:**
- Weekly active days
- Feature usage: sleep / activity / readiness / insights
- Engagement tier: high / medium / low

**Retention:**
- Week-N retention by registration cohort
- Lifecycle stage: Week 0 → Onboarding → Early → Established

**Health Outcomes:**
- Sleep score distribution by subscription tier
- Composite health index (sleep + activity + readiness)

---

## Stack

| Layer | Tool |
|---|---|
| Data generation | Python (pandas, numpy) |
| Transformation | dbt Core |
| Analytics | SQL (Snowflake-compatible) |
| Testing | dbt tests (not_null, unique, accepted_values, relationships) |
| Visualization | Tableau / Power BI |

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
│       │   ├── stg_events.sql
│       │   ├── stg_health_metrics.sql
│       │   └── schema.yml          ← sources + column tests
│       ├── intermediate/
│       │   ├── int_user_activity.sql
│       │   └── int_sleep_metrics.sql
│       └── marts/
│           ├── mart_user_engagement.sql
│           ├── mart_health_scores.sql
│           └── schema.yml          ← model tests + descriptions
├── sql/
│   └── analytical_queries.sql      ← North Star, retention, funnel, A/B test
├── python/
│   └── generate_data.py            ← synthetic data generator (500 users)
└── data/                           ← generated CSVs (gitignored)
    ├── raw_users.csv
    ├── raw_events.csv
    └── raw_health_metrics.csv
```

---

## dbt Tests Included

- `not_null` and `unique` on all primary keys
- `accepted_values` on subscription_type, engagement_tier, sleep_tier, lifecycle_stage
- `relationships` between fact and dimension tables

---

## Running the Data Generator

```bash
cd python
pip install pandas numpy
python generate_data.py
```

Generates ~500 users, ~1.5M events, ~300K health metric rows (2024–2026).

---

## About

**Julia Mosina** — BI & Data Analyst  
Metropolia University of Applied Sciences, Information Technology  
[LinkedIn](https://www.linkedin.com/in/julia-mosina) · Helsinki, Finland
