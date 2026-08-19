# Google Play Data Safety Questionnaire Guide — GrammarFix

This document provides exact responses for the Google Play Console **Data safety** questionnaire for `com.mogate.grammarfix`.

---

## Overview

- **Does your app collect or share any user data?**: Yes (Minimal anonymized telemetry for ad serving and crashes; **NO USER TEXT OR WRITING**).
- **Is all user data encrypted in transit?**: Yes.
- **Can users request data deletion?**: Yes (via local in-app data wipe & contact link).

---

## Detailed Data Breakdown

| Data Type | Collected | Shared | Purpose | Ephemeral |
|---|---|---|---|---|
| **User Content / Emails / Texts** | ❌ **NO** | ❌ **NO** | N/A (100% On-Device) | N/A |
| **Keystrokes / Typing Data** | ❌ **NO** | ❌ **NO** | N/A (No telemetry) | N/A |
| **Financial / Purchase Info** | ✅ YES (Tokens only) | ❌ NO | App functionality (Pro license verification via Google Play Billing / RevenueCat) | No |
| **Diagnostics / Crash Logs** | ✅ YES | ❌ NO | App stability & crash reporting (Filtered, zero user writing) | No |
| **Device or other IDs** | ✅ YES | ✅ YES | Advertising (AdMob non-personalized ads on Free tier) | No |

---

## Privacy Policy URL
`https://grammar-fix.mogate.tech/privacy`
