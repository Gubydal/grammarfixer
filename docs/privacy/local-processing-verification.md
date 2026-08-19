# GrammarFix On-Device Privacy & Zero-Leakage Verification

## 1. Privacy Architecture
GrammarFix operates on a strict zero-leakage local-first architecture:
- **English Grammar & Spelling**: Analyzed locally using on-device deterministic rules, context-aware homophone heuristics (`EnglishContextRules`), and fast transposition/typo mapping.
- **Multilingual Support**: Runs on-device with quantized lightweight model weights without sending text to cloud LLMs.
- **Android Keyboard (IME) & Spell Checker**: Run within the local Android OS process sandbox without network communication.
- **Sensitive Fields**: Passwords, PINs, OTPs, and credit card number inputs immediately disable suggestions and ephemeral learning.

## 2. Platform Permission Audit
The application manifest (`android/app/src/main/AndroidManifest.xml`) explicitly omits:
- `android.permission.BIND_ACCESSIBILITY_SERVICE` (NOT requested)
- `android.permission.SYSTEM_ALERT_WINDOW` (NOT requested)
- `android.permission.PACKAGE_USAGE_STATS` (NOT requested)

## 3. Verification & Testing
Local tests verify:
- Automated tests in `test/features/correction/owner_acceptance_test.dart` pass completely offline.
- URLs, email addresses, and hashtags are recognized as protected spans and never modified.
- No network requests are made during typing, editing, or correction flows.
