"""
Product Analytics Framework — Synthetic Data Generator
Simulates wearable health app data: users, events, health metrics

Output:
    data/raw_users.csv
    data/raw_events.csv
    data/raw_health_metrics.csv
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

N_USERS       = 500
START_DATE    = datetime(2024, 1, 1)
END_DATE      = datetime(2026, 4, 30)

COUNTRIES     = ['Finland', 'Sweden', 'Norway', 'Denmark', 'Estonia']
AGE_GROUPS    = ['18-24', '25-34', '35-44', '45+']
SUBSCRIPTIONS = ['free', 'plus', 'lifetime']
DEVICES       = ['Ring Gen3', 'Ring Gen4']
PLATFORMS     = ['ios', 'android']

EVENTS = [
    'ring_synced', 'sleep_viewed', 'activity_viewed',
    'readiness_viewed', 'insight_opened', 'settings_opened',
    'notification_tapped', 'app_opened'
]


def generate_users(n=N_USERS) -> pd.DataFrame:
    reg_dates = [
        START_DATE + timedelta(days=int(np.random.randint(0, (END_DATE - START_DATE).days)))
        for _ in range(n)
    ]
    return pd.DataFrame({
        'user_id':           [f'u{str(i).zfill(4)}' for i in range(1, n + 1)],
        'created_at':        [d.strftime('%Y-%m-%d %H:%M:%S') for d in reg_dates],
        'country':           np.random.choice(COUNTRIES, n, p=[0.45, 0.25, 0.15, 0.10, 0.05]),
        'device_model':      np.random.choice(DEVICES, n, p=[0.35, 0.65]),
        'app_version':       np.random.choice(['3.8', '3.9', '4.0', '4.1'], n),
        'subscription_type': np.random.choice(SUBSCRIPTIONS, n, p=[0.55, 0.35, 0.10]),
        'age_group':         np.random.choice(AGE_GROUPS, n, p=[0.20, 0.38, 0.28, 0.14]),
        'gender':            np.random.choice(['male', 'female', 'other'], n, p=[0.44, 0.53, 0.03]),
    })


def generate_events(users: pd.DataFrame) -> pd.DataFrame:
    rows = []
    event_id = 1

    for _, user in users.iterrows():
        reg_date  = datetime.strptime(user['created_at'], '%Y-%m-%d %H:%M:%S')
        is_paying = user['subscription_type'] != 'free'
        n_days    = max(1, min(
            int(np.random.normal(120 if is_paying else 60, 30)),
            (END_DATE - reg_date).days
        ))

        available_days = pd.date_range(reg_date, END_DATE).tolist()
        active_dates   = sorted(np.random.choice(available_days, size=min(n_days, len(available_days)), replace=False))

        for day in active_dates:
            session_id  = f's{event_id:07d}'
            event_names = np.random.choice(
                EVENTS, size=np.random.randint(2, 8),
                p=[0.25, 0.22, 0.15, 0.13, 0.10, 0.06, 0.05, 0.04]
            )
            for name in event_names:
                ts = pd.Timestamp(day) + pd.Timedelta(seconds=int(np.random.randint(0, 86400)))
                rows.append({
                    'event_id':        f'e{event_id:08d}',
                    'user_id':         user['user_id'],
                    'event_name':      name,
                    'event_timestamp': ts.strftime('%Y-%m-%d %H:%M:%S'),
                    'session_id':      session_id,
                    'platform':        np.random.choice(PLATFORMS, p=[0.68, 0.32]),
                    'app_version':     user['app_version'],
                    'properties':      '{}',
                })
                event_id += 1

    return pd.DataFrame(rows)


def generate_health_metrics(users: pd.DataFrame) -> pd.DataFrame:
    rows = []
    metric_id = 1
    base_sleep_by_age = {'18-24': 76, '25-34': 73, '35-44': 70, '45+': 67}

    for _, user in users.iterrows():
        reg_date   = datetime.strptime(user['created_at'], '%Y-%m-%d %H:%M:%S')
        base_sleep = base_sleep_by_age[user['age_group']]

        for d in pd.date_range(reg_date, END_DATE, freq='D'):
            if np.random.rand() > 0.15:  # ~85% ring worn rate
                total_sleep = int(np.clip(np.random.normal(420, 50), 240, 600))
                rows.append({
                    'metric_id':                  f'm{metric_id:08d}',
                    'user_id':                    user['user_id'],
                    'metric_date':                d.strftime('%Y-%m-%d'),
                    'sleep_score':                int(np.clip(np.random.normal(base_sleep, 10), 30, 100)),
                    'total_sleep_minutes':        total_sleep,
                    'deep_sleep_minutes':         int(total_sleep * np.random.uniform(0.13, 0.23)),
                    'rem_sleep_minutes':          int(total_sleep * np.random.uniform(0.18, 0.28)),
                    'sleep_efficiency_pct':       round(np.random.uniform(78, 98), 1),
                    'activity_score':             int(np.clip(np.random.normal(72, 12), 20, 100)),
                    'steps':                      int(np.clip(np.random.normal(8200, 2500), 500, 25000)),
                    'active_calories':            int(np.clip(np.random.normal(380, 100), 50, 1000)),
                    'inactive_hours':             round(np.random.uniform(4, 12), 1),
                    'readiness_score':            int(np.clip(np.random.normal(71, 10), 20, 100)),
                    'resting_heart_rate':         int(np.clip(np.random.normal(58, 8), 38, 90)),
                    'heart_rate_variability':     int(np.clip(np.random.normal(42, 15), 10, 120)),
                    'body_temperature_deviation': round(float(np.random.normal(0, 0.3)), 2),
                })
                metric_id += 1

    return pd.DataFrame(rows)


def main():
    print("=== Product Analytics Framework — Data Generation ===\n")
    os.makedirs("../data", exist_ok=True)

    print("Generating users...")
    users = generate_users()
    users.to_csv("../data/raw_users.csv", index=False)
    print(f"  raw_users.csv          ({len(users)} users)")

    print("Generating events...")
    events = generate_events(users)
    events.to_csv("../data/raw_events.csv", index=False)
    print(f"  raw_events.csv         ({len(events):,} events)")

    print("Generating health metrics...")
    health = generate_health_metrics(users)
    health.to_csv("../data/raw_health_metrics.csv", index=False)
    print(f"  raw_health_metrics.csv ({len(health):,} rows)")

    print("\nSample stats:")
    print(f"  Paying users:      {(users.subscription_type != 'free').sum()} / {len(users)}")
    print(f"  Avg sleep score:   {health.sleep_score.mean():.1f}")
    print(f"  Avg steps/day:     {health.steps.mean():.0f}")
    print(f"  Date range:        {health.metric_date.min()} to {health.metric_date.max()}")


if __name__ == "__main__":
    main()
