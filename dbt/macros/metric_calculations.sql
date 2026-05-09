-- Reusable macro: safe division (avoids division by zero)
{% macro safe_divide(numerator, denominator, default=0) %}
    case
        when {{ denominator }} = 0 or {{ denominator }} is null then {{ default }}
        else round({{ numerator }} * 1.0 / {{ denominator }}, 4)
    end
{% endmacro %}


-- Reusable macro: retention rate for a given day_n
-- Usage: {{ retention_rate('cohort_week', 7) }}
{% macro retention_rate(cohort_col, day_n) %}
    round(
        count(distinct case
            when day_n = {{ day_n }} then user_id
        end) * 100.0
        / nullif(max(cohort_size), 0),
    1)
{% endmacro %}


-- Reusable macro: WIAU flag (active user reached analytical value this week)
-- A user is insight-active if they fired insight_view at least once in the week
{% macro is_insight_active(event_name_col) %}
    max(case when {{ event_name_col }} = 'insight_view' then 1 else 0 end)
{% endmacro %}


-- Reusable macro: engagement tier classification
-- Thesis §3.1.3: high >= 5 active days, medium >= 2, else low
{% macro engagement_tier(active_days_col) %}
    case
        when {{ active_days_col }} >= 5 then 'high'
        when {{ active_days_col }} >= 2 then 'medium'
        else 'low'
    end
{% endmacro %}
