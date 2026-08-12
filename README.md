# Flutter_Template V2 (App Starter)

Production-oriented **Android** Flutter starter: Supabase auth (email +
Google), RevenueCat subscriptions (`pro` entitlement), AdMob with UMP,
a reusable design system, and Google Play release readiness built in.

The template is deliberately generic. It ships polished auth, shell,
Profile, Settings, paywall, feedback, and account-deletion flows so a new
app starts at production quality instead of a blank screen. App-specific
features (including the Home main feature and paywall copy) are meant to be
replaced per app.

## Stack

- Flutter 3.38+ / Dart 3.10+ (Android only)
- BLoC/Cubit state management (feature-first structure)
- Supabase: one project, one schema per app (`app_<slug>`), RLS
- RevenueCat: subscriptions, `pro` entitlement, localized runtime pricing
- Google Mobile Ads: UMP consent, app-open, banner, interstitial; Pro
  suppresses ads
- Google Play: in-app updates, store listing, in-app review, deletion URL
- Localization: Flutter gen-l10n, English default, per-app locales

## What the template contains

```text
lib/
  core/        config, navigation, services, l10n
  design/      colors, spacing, typography, theme, icons, components
  features/
    ads/       AdMob service + banner widget
    auth/      email + Google sign-in, reset, deletion
    feedback/  private stars + message stored in Supabase (RLS)
    home/      generic polished placeholder (replace per app)
    profile/   avatar, name, email, plan card
    settings/  feedback, rate, legal links, logout, delete
    shell/     tabs + floating glass bottom bar
    subscriptions/ RevenueCat service, Pro state, reusable paywall
supabase/      generic schema SQL + delete-account edge function
dart_defines/  per-app build configuration
tool/          new_app.ps1 bootstrap + 16 KB release check
docs/          migration, legal placeholders, setup, store, optional modules
test/          auth, Pro state, paywall, ads policy, shell, components
```

## Creating a new app

From the template root:

```powershell
.\tool\new_app.ps1 -AppName "My App" -PackageId "com.mogate.myapp" -Destination "..\myapp"
```

The script copies the template, renames the Dart package, Android
namespace/applicationId, deep-link scheme, Supabase schema
(`app_<slug>`), SQL, deletion function, and MainActivity path; writes
`dart_defines/<slug>.json`; creates `docs/setup/<slug>-setup.md`; and runs
`flutter pub get`.

Slug convention: `"My App"` -> `myapp` (lowercase, non-alphanumeric
characters removed, valid Dart package name).

## Configuring an app

Edit `dart_defines/<slug>.json` with your real values:

| Key | Where to find it |
| --- | --- |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Supabase Dashboard -> Project Settings -> API (anon key is client-safe) |
| `GOOGLE_WEB_CLIENT_ID` | Google Cloud Console -> APIs & Services -> Credentials (Web client) |
| `REVENUECAT_API_KEY` | RevenueCat Dashboard -> Project -> API Keys (public SDK key) |
| `ADMOB_APP_ID`, ad unit IDs | AdMob Dashboard -> Apps / Ad units (test IDs are the defaults) |

Run the app:

```powershell
flutter run --dart-define-from-file=dart_defines\<slug>.json
```

### Supabase

1. Run `supabase/sql/app_schema.sql` (schema `app_<slug>`; the bootstrap
   script rewrites it automatically).
2. Expose the schema in Project Settings -> API -> Exposed schemas.
3. Enable Email + Google providers; add the Google web client ID.
4. Add `<deep-link-scheme>://callback` to Authentication -> URL
   Configuration -> Redirect URLs.
5. Deploy the deletion function: `supabase functions deploy delete-account`.

### Google Sign-In

- Create a **Web** client ID and paste it into `GOOGLE_WEB_CLIENT_ID`.
- Register Android clients for the package with debug, upload/release, and
  Play App Signing SHA-1 fingerprints.

### RevenueCat

- Create an SDK key per app, one `pro` entitlement, and a current offering
  with monthly/annual packages. The paywall renders everything at runtime;
  never hardcode prices.
- `FORCE_PRO=true` builds a test APK that treats every user as Pro without
  RevenueCat. Keep it `false` for release.

### AdMob

- Create an app + ad units per app and put the IDs in the dart-defines file.
- Ads are suppressed for Pro users and hidden on auth, paywall, privacy,
  terms, and account-deletion flows.
- Future apps decide interstitial placement at natural breaks (never before
  value). A cadence-guarded helper exists on `AdService`.

## Legal URLs

Every app gets the Mogate subdomain pattern automatically, derived from the
slug:

```text
https://<slug>.mogate.tech/privacy
https://<slug>.mogate.tech/terms
https://<slug>.mogate.tech/delete-account
```

Set explicit `PRIVACY_URL` / `TERMS_URL` / `DELETE_ACCOUNT_URL` overrides in
the dart-defines file when needed. `docs/legal/` contains placeholder
outlines to turn into app-specific pages.

## Paywall

The paywall visual system (dark surface, accent CTA, benefit hierarchy, plan
cards, restore, terms/privacy, active-Pro state) is fixed by the template.
App-specific copy lives in `PaywallContent`:

```dart
PaywallContent(
  title: 'My App Pro',
  subtitle: 'Unlock the full power of My App.',
  benefits: ['No ads', 'Pro features'],
)
```

Prices always come from RevenueCat (`package.storeProduct.priceString`).

## Optional infrastructure

Workers, server-side Pro verification, usage credits, notifications, and
native review prompts are **not** enabled in the base. See:

- `docs/optional/server-pro-entitlement.md` - RevenueCat webhook ->
  Worker -> Supabase entitlement mirror (API-cost apps only)
- `docs/optional/usage-credits.md` - atomic usage/credit counters
- `docs/optional/native-review.md`, `docs/optional/notifications.md`
- `tool/templates/cloudflare_worker/` - generic Worker starter, copied only
  when an app prompt explicitly requires a Worker

## Release checklist (Google Play)

Verify the **current** Google Play requirements before each release; do not
assume the numbers below stay valid forever.

- Signing: create `android/key.properties` from
  `android/key.properties.example` (never commit it).
- Permissions: `AndroidManifest.xml` only requests `INTERNET`; do not add
  unused permissions.
- Privacy: publish the app-specific policy at
  `https://<slug>.mogate.tech/privacy`; it must match actual data flows.
- Terms + deletion URL live at the Mogate subdomain; in-app deletion is
  implemented through the Supabase edge function.
- Data Safety in Play Console must disclose Supabase, Google Sign-In,
  RevenueCat, and AdMob truthfully.
- App Access: account deletion and login methods must match the listing.
- Google Sign-In fingerprints: debug, upload, and Play App Signing.
- 16 KB page-size gate: build the AAB, then
  `.\tool\check_16kb.ps1`; upgrade any failing native dependency.
- Run Google Play Policy Insights before submission.
- Build the signed bundle:

  ```powershell
  flutter build appbundle --release --dart-define-from-file=dart_defines\<slug>.json
  ```

- In-app updates only work on Play-installed builds, not sideloaded APKs.

## Verification

```powershell
flutter analyze
flutter test
```

## Migration history

See [`docs/template-v2-migration.md`](docs/template-v2-migration.md) for the
full V2 migration record and the VidBrief reference comparison.
