# Account Deletion (Template Placeholder)

_Last updated: <set per app>_

> Placeholder for the external deletion page published at
> `https://<slug>.mogate.tech/delete-account`. The template links to this
> URL from Settings; the page itself is a website task, not part of the app.

## App supports deletion inside the app: Yes

In-app deletion steps:

1. Open the app.
2. Open Settings.
3. Choose Delete Account.
4. Confirm deletion.

What will be deleted:

- Account profile and email
- Feedback you submitted
- Supabase authentication record
- Any app-specific rows added to the deletion function

What may be retained:

- Google Play purchase receipts and transaction records, governed by
  Google's terms and retention policy.
- Temporary copies in backups, purged according to the backup retention
  cycle.
- Records the app is legally required to keep.
