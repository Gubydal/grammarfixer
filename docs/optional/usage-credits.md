# Optional: AI/Usage Credit System

## When to use

When an app has server-side paid generation (AI, OCR, paid APIs) and needs
free allowances or Pro monthly credits. Not part of the base template.

## Pattern (VidBrief-derived, generalized)

- `usage_periods` table keyed by `(user_id, period_key)` with atomic
  counters (`free_summaries_used`, `pro_credits_used`).
- A server-only `reserve_usage(...)` function that locks the period row
  (`pg_advisory_xact_lock`), checks the allowance, and increments atomically.
- A `release_usage(...)` refund path when the provider call fails.
- Monthly reset via period keys (`YYYY-MM`) rather than cron deletion.
- RLS: users can only read their own counters; only the Worker (service
  role) can execute the mutations.

## Rules

- No tables created by default; future AI/API app prompts enable this
  module explicitly.
- Ad suppression never depends on remaining credits: Pro = no ads even
  with exhausted allowance.
