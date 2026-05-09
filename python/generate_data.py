"""
Product Analytics Framework — Synthetic Data Generator
Wearable Health Application · Julia Mosina · Bachelor's Thesis, Metropolia UAS 2026

Generates a 120-day synthetic dataset for 1000 users with three behavioral types.
Thesis §4 Implementation: casual (50%), regular (35%), power (15%) user segments.

Output files (data/):
    raw_users.csv
    raw_events.csv
    raw_sessions.csv
    raw_subscriptions.csv
    raw_health_metrics.csv
    raw_feature_usage.csv
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

N_USERS            = 1000
OBS_DAYS           = 120          # observation period per user (Thesis §4)
COHORT_START       = datetime(2025, 1, 1)
COHORT_END         = datetime(2025, 4, 30)

COUNTRIES          = ['Finland', 'Sweden', 'Norway', 'Denmark', 'Estonia']
AGE_GROUPS         = ['18-24', '25-34', '35-44', '45+']
PLATFORMS          = ['ios', 'android']
DEVICES            = ['Ring Gen3', 'Ring Gen4']
ACQ_SOURCES        = ['organic', 'paid_social', 'referral', 'app_store_search', 'influencer']
PAYMENT_PROVIDERS  = ['stripe', 'apple_pay', 'google_pay']

# Three behavioral types (Thesis §4)
USER_TYPES = ['casual', 'regular', 'power']
USER_TYPE_WEIGHTS = [0.50, 0.35, 0.15]

# Subscription probability by user type
SUB_PROFILE = {
    'casual':  {'free': 0.87, 'plus': 0.11, 'lifetime': 0.02},
    'regular': {'free': 0.45, 'plus': 0.45, 'lifetime': 0.10},
    'power':   {'free': 0.10, 'plus': 0.68, 'lifetime': 0.22},
}

# Active days per OBS_DAYS period by user type
ACTIVE_DAY_PROFILE = {
    'casual':  {'mean': 25, 'std': 10},
    'regular': {'mean': 60, 'std': 15},
    'power':   {'mean': 95, 'std': 10},
}


def _reg_date():
    span = (COHORT_END - COHORT_START).days
    return COHORT_START + timedelta(days=int(np.random.randint(0, span - OBS_DAYS)))


def generate_users() -> pd.DataFrame:
    user_types = np.random.choice(USER_TYPES, N_USERS, p=USER_TYPE_WEIGHTS)
    sub_types  = [
        np.random.choice(
            list(SUB_PROFILE[ut].keys()),
            p=list(SUB_PROFILE[ut].values())
        )
        for ut in user_types
    ]
    reg_dates = [_reg_date() for _ in range(N_USERS)]

    return pd.DataFrame({
        'user_id':            [f'u{i:04d}' for i in range(1, N_USERS + 1)],
        'registration_date':  [d.strftime('%Y-%m-%d') for d in reg_dates],
        'country':            np.random.choice(COUNTRIES, N_USERS, p=[0.45, 0.25, 0.15, 0.10, 0.05]),
        'acquisition_source': np.random.choice(ACQ_SOURCES, N_USERS, p=[0.40, 0.25, 0.15, 0.12, 0.08]),
        'platform':           np.random.choice(PLATFORMS, N_USERS, p=[0.65, 0.35]),
        'device_model':       np.random.choice(DEVICES, N_USERS, p=[0.35, 0.65]),
        'app_version':        np.random.choice(['4.0', '4.1', '4.2'], N_USERS, p=[0.20, 0.45, 0.35]),
        'subscription_type':  sub_types,
        'user_type':          user_types,
        'age_group':          np.random.choice(AGE_GROUPS, N_USERS, p=[0.20, 0.38, 0.28, 0.14]),
        'gender':             np.random.choice(['male', 'female', 'other'], N_USERS, p=[0.44, 0.53, 0.03]),
    })


def _active_days_for_user(user, reg_date):
    profile = ACTIVE_DAY_PROFILE[user['user_type']]
    n_active = int(np.clip(np.random.normal(profile['mean'], profile['std']), 3, OBS_DAYS))
    all_days = [reg_date + timedelta(days=d) for d in range(OBS_DAYS)]
    return sorted(np.random.choice(all_days, size=min(n_active, OBS_DAYS), replace=False))


def generate_events_and_sessions(users: pd.DataFrame):
    events_rows   = []
    sessions_rows = []
    event_id      = 1
    session_id    = 1

    # Event weights per user type (insight/recommendation events more likely for power users)
    daily_event_pool = {
        'casual': {
            'events': ['app_open', 'sleep_view', 'readiness_view', 'activity_view', 'trend_view',
                       'insight_view', 'notification_click'],
            'probs':  [0.35, 0.25, 0.18, 0.12, 0.05, 0.03, 0.02],
        },
        'regular': {
            'events': ['app_open', 'sleep_view', 'readiness_view', 'activity_view', 'trend_view',
                       'insight_view', 'recommendation_click', 'notification_click'],
            'probs':  [0.25, 0.22, 0.18, 0.12, 0.08, 0.08, 0.04, 0.03],
        },
        'power': {
            'events': ['app_open', 'sleep_view', 'readiness_view', 'activity_view', 'trend_view',
                       'insight_view', 'recommendation_click', 'notification_click'],
            'probs':  [0.18, 0.18, 0.15, 0.12, 0.10, 0.14, 0.08, 0.05],
        },
    }
    events_per_session = {'casual': (1, 4), 'regular': (2, 6), 'power': (3, 9)}

    for _, user in users.iterrows():
        uid      = user['user_id']
        utype    = user['user_type']
        platform = user['platform']
        version  = user['app_version']
        reg_date = datetime.strptime(user['registration_date'], '%Y-%m-%d')

        # Day 0: install + onboarding events
        install_ts = reg_date + timedelta(hours=int(np.random.randint(8, 20)))
        for ev in ['app_install', 'app_first_open', 'onboarding_complete', 'device_connected']:
            ts = install_ts + timedelta(minutes=event_id % 30)
            events_rows.append({
                'event_id':        f'e{event_id:08d}',
                'user_id':         uid,
                'session_id':      f'ses{session_id:07d}',
                'event_name':      ev,
                'event_timestamp': ts.strftime('%Y-%m-%d %H:%M:%S'),
                'platform':        platform,
                'app_version':     version,
                'event_properties': '{}',
            })
            event_id += 1

        onboarding_sess_start = install_ts
        onboarding_sess_end   = install_ts + timedelta(minutes=15)
        sessions_rows.append({
            'session_id':       f'ses{session_id:07d}',
            'user_id':          uid,
            'session_start':    onboarding_sess_start.strftime('%Y-%m-%d %H:%M:%S'),
            'session_end':      onboarding_sess_end.strftime('%Y-%m-%d %H:%M:%S'),
        })
        session_id += 1

        # Paywall view for non-free users (before subscription)
        is_paying = user['subscription_type'] != 'free'
        if is_paying or (utype != 'casual' and np.random.rand() < 0.3):
            pw_day  = reg_date + timedelta(days=int(np.random.randint(1, 15)))
            pw_ts   = pw_day + timedelta(hours=int(np.random.randint(9, 22)))
            events_rows.append({
                'event_id':        f'e{event_id:08d}',
                'user_id':         uid,
                'session_id':      f'ses{session_id:07d}',
                'event_name':      'paywall_view',
                'event_timestamp': pw_ts.strftime('%Y-%m-%d %H:%M:%S'),
                'platform':        platform,
                'app_version':     version,
                'event_properties': '{}',
            })
            event_id += 1

        # Daily sessions
        active_days = _active_days_for_user(user, reg_date)
        pool        = daily_event_pool[utype]
        min_ev, max_ev = events_per_session[utype]

        for day in active_days:
            n_sessions_today = np.random.randint(1, 3)
            session_start_hour = np.random.randint(6, 23)

            for s in range(n_sessions_today):
                sess_start = day + timedelta(hours=session_start_hour + s * 3,
                                             minutes=int(np.random.randint(0, 60)))
                sess_events = np.random.choice(
                    pool['events'],
                    size=np.random.randint(min_ev, max_ev),
                    p=pool['probs'],
                    replace=True,
                )
                sess_duration_min = int(np.random.randint(2, 25))
                sess_end = sess_start + timedelta(minutes=sess_duration_min)

                sessions_rows.append({
                    'session_id':    f'ses{session_id:07d}',
                    'user_id':       uid,
                    'session_start': sess_start.strftime('%Y-%m-%d %H:%M:%S'),
                    'session_end':   sess_end.strftime('%Y-%m-%d %H:%M:%S'),
                })

                for i, ev in enumerate(sess_events):
                    ts = sess_start + timedelta(seconds=int(i * sess_duration_min * 60 / max(len(sess_events), 1)))
                    events_rows.append({
                        'event_id':        f'e{event_id:08d}',
                        'user_id':         uid,
                        'session_id':      f'ses{session_id:07d}',
                        'event_name':      ev,
                        'event_timestamp': ts.strftime('%Y-%m-%d %H:%M:%S'),
                        'platform':        platform,
                        'app_version':     version,
                        'event_properties': '{}',
                    })
                    event_id += 1

                session_id += 1

    return pd.DataFrame(events_rows), pd.DataFrame(sessions_rows)


def generate_subscriptions(users: pd.DataFrame) -> pd.DataFrame:
    rows = []
    sub_id = 1

    for _, user in users.iterrows():
        if user['subscription_type'] == 'free':
            continue

        reg_date  = datetime.strptime(user['registration_date'], '%Y-%m-%d')
        start_day = reg_date + timedelta(days=int(np.random.randint(1, 20)))

        # Monthly billing, up to 3 renewals within OBS_DAYS
        current_start = start_day
        n_periods     = 1 + np.random.binomial(3, 0.745)  # ~74.5% renewal rate (Thesis §4.1.3)

        for period in range(n_periods):
            period_end = current_start + timedelta(days=30)
            if period == n_periods - 1:
                # Last period — could be active or cancelled/expired
                churn = np.random.rand() < 0.255
                status = 'cancelled' if churn else 'active'
            else:
                status = 'renewed'

            rows.append({
                'subscription_id':     f'sub{sub_id:06d}',
                'user_id':             user['user_id'],
                'subscription_start':  current_start.strftime('%Y-%m-%d'),
                'subscription_end':    period_end.strftime('%Y-%m-%d'),
                'subscription_status': status,
                'subscription_type':   user['subscription_type'],
                'payment_provider':    np.random.choice(
                    PAYMENT_PROVIDERS,
                    p=[0.50, 0.32, 0.18] if user['platform'] == 'ios' else [0.55, 0.10, 0.35]
                ),
            })
            sub_id          += 1
            current_start    = period_end

            if status in ('cancelled', 'expired'):
                break

    return pd.DataFrame(rows)


def generate_feature_usage(users: pd.DataFrame) -> pd.DataFrame:
    features = ['sleep_insights', 'readiness_score', 'activity_trends',
                'weekly_summary', 'health_alerts', 'goal_tracking']
    rows = []
    fu_id = 1

    feature_probs = {
        'casual':  [0.50, 0.20, 0.15, 0.10, 0.03, 0.02],
        'regular': [0.30, 0.22, 0.18, 0.15, 0.08, 0.07],
        'power':   [0.22, 0.18, 0.17, 0.15, 0.15, 0.13],
    }

    for _, user in users.iterrows():
        reg_date  = datetime.strptime(user['registration_date'], '%Y-%m-%d')
        n_usages  = int(np.clip(np.random.exponential(15 if user['user_type'] == 'casual'
                                                       else 40 if user['user_type'] == 'regular'
                                                       else 80), 1, OBS_DAYS * 2))
        probs = feature_probs[user['user_type']]

        for _ in range(n_usages):
            feat_day = reg_date + timedelta(days=int(np.random.randint(0, OBS_DAYS)))
            feat_ts  = feat_day + timedelta(hours=int(np.random.randint(6, 23)),
                                            minutes=int(np.random.randint(0, 60)))
            rows.append({
                'feature_usage_id': f'fu{fu_id:08d}',
                'user_id':          user['user_id'],
                'feature_name':     np.random.choice(features, p=probs),
                'used_at':          feat_ts.strftime('%Y-%m-%d %H:%M:%S'),
                'session_duration_seconds': int(np.random.randint(10, 300)),
            })
            fu_id += 1

    return pd.DataFrame(rows)


def generate_health_metrics(users: pd.DataFrame) -> pd.DataFrame:
    rows = []
    metric_id  = 1
    sleep_by_age = {'18-24': 76, '25-34': 73, '35-44': 70, '45+': 67}

    for _, user in users.iterrows():
        reg_date   = datetime.strptime(user['registration_date'], '%Y-%m-%d')
        base_sleep = sleep_by_age[user['age_group']]

        for d in pd.date_range(reg_date, reg_date + timedelta(days=OBS_DAYS - 1), freq='D'):
            if np.random.rand() > 0.15:
                total_sleep = int(np.clip(np.random.normal(420, 50), 240, 600))
                rows.append({
                    'metric_id':                  f'm{metric_id:08d}',
                    'user_id':                    user['user_id'],
                    'metric_date':                d.strftime('%Y-%m-%d'),
                    'sleep_score':                int(np.clip(np.random.normal(base_sleep, 10), 30, 100)),
                    'total_sleep_minutes':        total_sleep,
                    'deep_sleep_minutes':         int(total_sleep * np.random.uniform(0.13, 0.23)),
                    'rem_sleep_minutes':          int(total_sleep * np.random.uniform(0.18, 0.28)),
                    'sleep_efficiency_pct':       round(float(np.random.uniform(78, 98)), 1),
                    'activity_score':             int(np.clip(np.random.normal(72, 12), 20, 100)),
                    'steps':                      int(np.clip(np.random.normal(8200, 2500), 500, 25000)),
                    'active_calories':            int(np.clip(np.random.normal(380, 100), 50, 1000)),
                    'readiness_score':            int(np.clip(np.random.normal(71, 10), 20, 100)),
                    'resting_heart_rate':         int(np.clip(np.random.normal(58, 8), 38, 90)),
                    'heart_rate_variability':     int(np.clip(np.random.normal(42, 15), 10, 120)),
                    'body_temperature_deviation': round(float(np.random.normal(0, 0.3)), 2),
                })
                metric_id += 1

    return pd.DataFrame(rows)


def main():
    print("=== Product Analytics Framework — Data Generation ===")
    print(f"    Users: {N_USERS} | Observation period: {OBS_DAYS} days\n")

    output_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
    os.makedirs(output_dir, exist_ok=True)

    print("Generating users...")
    users = generate_users()
    users.to_csv(os.path.join(output_dir, 'raw_users.csv'), index=False)
    print(f"  raw_users.csv          — {len(users):,} users")
    print(f"    casual: {(users.user_type == 'casual').sum()}, "
          f"regular: {(users.user_type == 'regular').sum()}, "
          f"power: {(users.user_type == 'power').sum()}")

    print("Generating events + sessions...")
    events, sessions = generate_events_and_sessions(users)
    events.to_csv(os.path.join(output_dir, 'raw_events.csv'), index=False)
    sessions.to_csv(os.path.join(output_dir, 'raw_sessions.csv'), index=False)
    print(f"  raw_events.csv         — {len(events):,} events")
    print(f"  raw_sessions.csv       — {len(sessions):,} sessions")

    print("Generating subscriptions...")
    subscriptions = generate_subscriptions(users)
    subscriptions.to_csv(os.path.join(output_dir, 'raw_subscriptions.csv'), index=False)
    paying = (users.subscription_type != 'free').sum()
    print(f"  raw_subscriptions.csv  — {len(subscriptions):,} rows ({paying} paying users)")

    print("Generating feature usage...")
    feature_usage = generate_feature_usage(users)
    feature_usage.to_csv(os.path.join(output_dir, 'raw_feature_usage.csv'), index=False)
    print(f"  raw_feature_usage.csv  — {len(feature_usage):,} rows")

    print("Generating health metrics...")
    health = generate_health_metrics(users)
    health.to_csv(os.path.join(output_dir, 'raw_health_metrics.csv'), index=False)
    print(f"  raw_health_metrics.csv — {len(health):,} rows")

    print("\nKey metric targets (Thesis Table 1):")
    print(f"  Paying users (conversion ~19.6%): {paying} / {N_USERS} = {paying/N_USERS*100:.1f}%")
    print(f"  Sub records with 'renewed':        "
          f"{(subscriptions.subscription_status == 'renewed').sum()}")
    print(f"  Avg sleep score:                   {health.sleep_score.mean():.1f}")
    print(f"  Date range:                        "
          f"{users.registration_date.min()} → {users.registration_date.max()}")


if __name__ == "__main__":
    main()
