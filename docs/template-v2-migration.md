# Flutter_Template V2 Migration

_Date: 2026-08-12_

This document records how the base `Flutter_Template` was upgraded to V2
using VidBrief as a **reference implementation only**. VidBrief is a finished
production app; the template is deliberately **not** "VidBrief minus the
summary feature". Every candidate file/component was judged with one
question:

> Would 3 unrelated future Mogate apps reasonably reuse this?

Yes -> migrate/generalize. No -> keep out. Maybe -> optional module/doc.

## Reusable improvements migrated from VidBrief

### Design system (`lib/design/`)

- **Colors** (`app_colors.dart`): VidBrief's semantic token set (brand
  accent, light/dark neutrals, container/variant/outline roles) replaced the
  Material-seed-based palette. Token names are generic; only the default
  brand color comes from VidBrief's visual language.
- **Typography** (`app_theme.dart`, `app_typography.dart`): promoted the
  Lexend Deca + Rubik pairing (both bundled, OFL-licensed) with explicit
  heading/body/label roles, dark/light support, and text scaling. No ad-hoc
  font sizes remain on migrated screens.
- **Icons** (`app_icons.dart`): one icon abstraction point backed by the
  Flutter_icons SVG library. Future custom icon sets swap in at this single
  file.
- **Components**: promoted the variant-aware `AppButton`, labeled/validated
  `AppTextField`, polished loading/empty/error `AppStateView`, `AppChip`,
  `AppSectionTitle`, `AppStatusTag`, and the floating glass `AppBottomBar`.
  New generic components extracted from VidBrief's private widgets:
  `AppSettingsTile` (from Profile's `_SettingsTile`) and `AppPlanCard`
  (from Profile's `_PlanCard`). Added a neutral `AppLogo` so auth/Profile
  have no third-party branding.

### Paywall (`lib/features/subscriptions/`)

- Promoted VidBrief's premium dark paywall visual language: dark surface,
  gold accent, Pro header, benefit list, restore, terms/privacy, and
  active-Pro state.
- Added a reusable `PaywallContent` model so title/subtitle/benefits are
  configurable per app. Prices always render from RevenueCat at runtime.
- Added monthly/annual **plan cards** with selected state and a
  "Best value" badge (configurable via `PaywallContent.recommendedPlan`).

### Monetization & ads

- `SubscriptionCubit`: `forcePro` test override + injectable `isProCheck`
  seam (testable without the RevenueCat SDK).
- `OfferingsCubit`: injectable fetch/purchase seams and `packages` getter.
- `AdService`: generalized the cadence-guarded interstitial policy into a
  pure, testable `InterstitialAdPolicy` with `maybeShowInterstitialIfDue`.
  Placement stays an app decision.
- `AppBannerAd`: collapses cleanly when the ad fails to load and renders in
  a rounded container.
- Android manifest: added the `https` VIEW query so `canLaunchUrl` works for
  legal URLs.

### Auth / Profile / Settings / Feedback / Shell

- Auth pages: VidBrief's centered layout with labeled fields, branded
  header, full-width Google button, and proper forgot-password dialog.
- Profile: polished avatar, name/email, plan card with upgrade CTA.
- Settings: `AppSettingsTile` rows, external web deletion link, logout and
  in-app deletion with confirmations.
- Shell: floating glass bottom bar with a **configurable destination list**;
  banner placement and Pro suppression kept from the template's 4-tab
  structure.
- App-level cubits now live above `MaterialApp` so pushed routes can read
  them (VidBrief improvement).
- `ErrorWidget.builder` shows a readable error surface instead of a gray box.

### Localization

- Promoted Flutter's standard gen-l10n infrastructure (`l10n.yaml`,
  `generate: true`, `flutter_localizations`, `intl`) with a single English
  ARB containing only reusable base strings. VidBrief's Arabic/French/
  Spanish translations and VidBrief-specific strings were **not** copied;
  apps add their own locales.

### Release discipline

- `tool/check_16kb.ps1` (16 KB page-size gate) promoted from VidBrief.
- Android 12+ splash (`values-v31`, `values-night-v31`) and a generic
  adaptive launcher icon promoted with neutral artwork.
- AppConfig legal URLs now follow the Mogate subdomain pattern
  (`https://<slug>.mogate.tech/...`) with explicit per-app overrides.

## App-specific pieces excluded from VidBrief

Intentionally **not** migrated:

- `features/summary/` (Quick Brief, Detailed, Study Notes, Action Plan,
  Ask VidBrief, history, usage/credits)
- Gemini video processing, YouTube URL parsing/validation, video metadata
- `vidbrief_api_client`, Worker `/summarize` and `/ask` endpoints
- `worker/vidbrief-api` as-is (a small generic Worker starter is provided in
  `tool/templates/cloudflare_worker/` instead)
- VidBrief branding: logo SVGs, illustration, store listing, legal copy,
  pricing, product IDs, ad unit IDs, Worker URL, debug SHA-1 fingerprints
- `share_plus` (no generic share feature in the base; add per app when a
  share flow exists)
- `http` dependency (only needed by the optional Worker client; the base app
  talks to Supabase directly)
- VidBrief's `reviews` table and review sheet (private star-rating sheet is
  product-specific; the template exposes native review via
  `PlayServices`)
- VidBrief's `reviews`/`summaries`/`usage_periods`/
  `subscription_entitlements` SQL and `reserve_usage`/`release_usage`
  functions (documented as optional patterns, not shipped)

## Files migrated (by stage)

1. **Design system**: `lib/design/app_colors.dart`, `app_theme.dart`,
   `app_typography.dart` (new), `app_icons.dart` (new),
   `app_spacing.dart` (unchanged), `components/*` (promoted/added).
2. **Core**: `lib/core/config/app_config.dart` (legal URLs, forcePro,
   optional API base URL), `lib/core/l10n/l10n.dart` (new).
3. **Features**: `ads/*`, `subscriptions/*` (paywall, cubits, states,
   `paywall_content.dart`), `auth/*` pages, `home/*`, `profile/*`,
   `settings/*`, `feedback/*`, `shell/*`.
4. **Entry**: `lib/main.dart`.
5. **Android**: manifest queries, v31 splash, adaptive icon.
6. **Backend**: `supabase/sql/app_schema.sql` (idempotent),
   `supabase/functions/delete-account/index.ts`.
7. **Tooling**: `tool/new_app.ps1` (V2 bootstrap), `tool/check_16kb.ps1`.
8. **Docs**: `docs/` tree, README.
9. **Tests**: existing tests updated + new subscription/paywall/ad-policy/
   shell/config/component tests.

## Architecture changes

- Providers (Auth, Subscription, Offerings) moved **above** `MaterialApp`
  so pushed routes (settings, feedback, paywall) can read cubits.
- Shell destinations are now a configurable list passed to the glass
  `AppBottomBar`; the default stays Home / Profile / Settings / Upgrade.
- Paywall copy is data (`PaywallContent`) rather than hardcoded strings;
  the visual structure is fixed by the template.
- Ad interstitial rules extracted into a pure policy class.
- Account deletion function documents the exact pattern for adding
  app-specific tables.

## Dependency changes

Added:
- `flutter_localizations` + `intl` (gen-l10n localization infrastructure).
- `flutter_svg` (icon abstraction layer).
- Bundled fonts: Lexend Deca + Rubik (OFL-licensed, redistributable).

Removed/not inherited from VidBrief:
- `share_plus` (no base share feature; per-app decision).
- `http` (only needed by an optional Worker client; keep base lean).

Kept unchanged:
- `flutter_bloc`, `supabase_flutter`, `google_sign_in`,
  `flutter_secure_storage`, `purchases_flutter`, `google_mobile_ads`,
  `in_app_update`, `in_app_review`, `url_launcher`, `shared_preferences`.
- Versions are the working stable set already verified in the base.

## What was intentionally left out of the base

- `lib/features/summary/` and all VidBrief product logic.
- VidBrief's `worker/vidbrief-api` source (generic starter only).
- VidBrief legal/store/business copy (placeholder docs provided).
- Machine-specific data: local.properties, GeneratedPluginRegistrant,
  debug fingerprints, local Worker URLs, personal paths.
- Obsolete Google Sites privacy URL (replaced by the Mogate subdomain
  pattern).
