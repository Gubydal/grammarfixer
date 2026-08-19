# GrammarFix Setup Checklist

Fill in the real values below after copying the template with tool/new_app.ps1.

## 1. Supabase

- Create one Supabase project (or reuse the shared one).
- Run supabase/sql/app_schema.sql in the SQL editor (schema: app_grammarfix).
- Add app_grammarfix to Project Settings -> API -> Exposed schemas.
- Authentication -> Providers: enable Email and Google; add the Google web client ID.
- Authentication -> URL Configuration -> Redirect URLs: add com.mogate.grammarfix://callback.
- Deploy the deletion function: supabase functions deploy delete-account.

## 2. Google Sign-In

- Create a Web client ID in Google Cloud Console and put it in dart_defines/grammarfix.json (GOOGLE_WEB_CLIENT_ID).
- Register Android clients for com.mogate.grammarfix with debug, upload, and Play App Signing SHA-1 fingerprints.

## 3. RevenueCat

- Create a project, an SDK key, a pro entitlement, and a current offering with monthly/annual packages. Put the SDK key in REVENUECAT_API_KEY.

## 4. AdMob

- Create an app + ad units and put the IDs in dart_defines/grammarfix.json. Test IDs are the defaults.

## 5. Legal URLs

- Legal URLs default to https://grammarfix.mogate.tech/privacy, https://grammarfix.mogate.tech/terms, and https://grammarfix.mogate.tech/delete-account.
- Set explicit overrides in dart_defines/grammarfix.json if needed.

## 6. Run

```powershell
flutter run --dart-define-from-file=dart_defines/grammarfix.json
```