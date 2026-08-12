# Optional: Server-Side Pro Entitlement

## When to use

Only when a backend must know Pro securely before authorizing expensive
work: Gemini/OCR/generation APIs, quotas, or any paid API the client could
otherwise bypass. **Normal apps do not need this.** RevenueCat client
entitlement (ads off, local UI) is enough.

## Flow

```text
RevenueCat
  -> webhook (purchase/renewal/cancellation/expiration/billing)
  -> trusted Worker (verify webhook secret)
  -> Supabase app_<slug>.subscription_entitlements mirror
  -> paid API authorization (Worker checks mirror before serving)
```

## Building blocks

1. `subscription_entitlements` table in the app schema:
   `user_id`, `entitlement`, `is_active`, `expires_at`, `updated_at`.
   RLS: users can only `select` their own row; only the Worker (service
   role) writes.
2. RevenueCat webhook route in the Worker with `Authorization: Bearer
   <REVENUECAT_WEBHOOK_SECRET>` and timing-safe comparison.
3. Worker checks the mirror before each paid call and refuses when inactive.
4. Delete-account function removes the entitlement row.

No table is created by default in the template.
