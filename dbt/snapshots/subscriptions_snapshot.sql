-- Snapshot: tracks subscription status changes over time
-- Critical for accurate subscription retention and churn analysis
-- Captures: status updates, cancellations, renewals
-- Thesis §4.2.5: snapshots directory used to track subscription state history

{% snapshot subscriptions_snapshot %}

{{
    config(
        target_schema  = 'snapshots',
        unique_key     = 'subscription_id',
        strategy       = 'check',
        check_cols     = ['subscription_status', 'subscription_end'],
    )
}}

select
    subscription_id,
    user_id,
    subscription_start,
    subscription_end,
    subscription_status,
    subscription_type,
    payment_provider
from {{ source('raw', 'subscriptions') }}

{% endsnapshot %}
