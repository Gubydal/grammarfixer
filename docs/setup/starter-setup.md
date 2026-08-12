# Template Setup Checklist (app: <slug>)

Everything below is a manual, one-time configuration. Secrets are never
shipped in the Flutter app.

## 1. Supabase

1. Use one shared Supabase project (or create one).
2. Open **SQL Editor** and run `supabase/sql/app_schema.sql`. It creates the
   `app_<slug>` schema with `profiles` and `feedback` plus RLS.
3. **Project Settings -> API**: add `app_<slug>` to **Exposed schemas**;
   copy the project URL and anon key into `dart_defines/<slug>.json`
   (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
4. **Authentication -> Providers**: enable Email and Google; paste the
   Google web client ID.
5. **Authentication -> URL Configuration -> Redirect URLs**: add
   `<deep-link-scheme>://callback`.
6. Deploy the deletion function:

   ```bash
   supabase functions deploy delete-account
   ```

## 2. Google Sign-In

- Create a **Web** client ID in Google Cloud Console and paste it into
  `GOOGLE_WEB_CLIENT_ID`.
- Register Android clients for the app package with debug, upload, and Play
  App Signing SHA-1 fingerprints.

## 3. RevenueCat

- Create a project and an SDK key; put the key in `REVENUECAT_API_KEY`.
- Create a `pro` entitlement.
- Create a current offering with monthly and annual packages. The paywall
  reads everything at runtime (no code changes).

## 4. AdMob

- Create an app and ad units; put the IDs in the dart-defines file
  (`ADMOB_APP_ID`, banner, interstitial, app-open). Test IDs are defaults.
- Ads are suppressed for Pro users and on trust-sensitive screens.

## 5. Legal URLs

Legal URLs default to:

```text
https://<slug>.mogate.tech/privacy
https://<slug>.mogate.tech/terms
https://<slug>.mogate.tech/delete-account
```

Set explicit overrides in the dart-defines file when needed.

## 6. Release gates

- `flutter analyze`, `flutter test`
- 16 KB page-size check: `tool/check_16kb.ps1` after building the AAB
- Verify the current Google Play target API requirement before release
- Run Google Play Policy Insights before submission
