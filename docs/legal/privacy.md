# Privacy Policy (Template Placeholder)

_Effective date: <set per app>_

> This is a **placeholder** for the template. Every generated app must
> replace it with an app-specific policy that matches the actual SDKs,
> permissions, data collected, storage, sharing/processors, authentication,
> advertising, subscriptions, external APIs, retention, and deletion
> behavior of that app. Publish the final text at
> `https://<slug>.mogate.tech/privacy`.

## Suggested outline

1. **App and developer** - who operates the app and what it does.
2. **Information collected** - account info, user content, usage data,
   feedback, subscription state. List only what the app actually collects.
3. **How information is used** - account continuity, features, ads removal,
   support, improvements.
4. **Third-party services** - Supabase (auth/database), Google Sign-In,
   RevenueCat (purchases), Google AdMob (ads for free users), Google Play,
   and any app-specific backend/Worker.
5. **Data retention and deletion** - retention periods and what account
   deletion removes (profile, feedback, auth record, app-specific rows).
6. **Children's privacy** - minimum age and no-knowing-collection statement.
7. **Security** - secrets never ship in the client; RLS; server-side
   authorization where applicable.
8. **Changes** - how users are notified.
9. **Contact** - support email.

## Template data flows to disclose

- Supabase: email + Google sign-in, profile mirror, private feedback.
- RevenueCat: subscription state, `pro` entitlement.
- Google AdMob: ads for free users (app-open, banner, interstitial), UMP
  consent, ad identifiers; Pro users see no ads.
- Google Play: purchases, in-app updates/review.
