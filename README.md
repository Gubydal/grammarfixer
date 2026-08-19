# GrammarFix

**Privacy-First On-Device Grammar & Spelling Corrector for Android**

GrammarFix is a native, local-first grammar correction tool built by Mogate. It provides instant, high-precision grammar, spelling, and style correction directly on the user's phone.

---

## Key Features

- **100% On-Device Privacy**: No user text ever leaves the phone. No cloud AI, no remote text logging, no telemetry with user writing.
- **Guest-First Design**: No sign-in or account creation required. Open the app and start writing immediately.
- **Deep Android Integration**:
  - `ACTION_PROCESS_TEXT`: Highlight text in any app (Messages, Browser, Notes, WhatsApp) and tap **"Fix grammar"** to review and replace selected text seamlessly.
  - `ACTION_SEND`: Share text directly into GrammarFix.
- **Dual Local Inference Engines**:
  - **English**: Powered by **Harper** (`harper-core` via Rust C-ABI FFI wrapper), executing in <5ms with 16 KB memory page-size compatibility.
  - **Multilingual (Arabic, French, Spanish, German, Portuguese, Italian)**: Powered by on-device quantized **Qwen3-0.6B** via LiteRT-LM, delivered via Google Play On-Demand Asset Delivery.
- **Interactive Review Mode**: Visual color-coded diff highlights (Green/Amber), bottom sheet suggestion drawer, custom user dictionary whitelist, and instant one-tap **Fix All**.
- **Arabic Right-to-Left (RTL)**: Native RTL layout, Arabic typographic hierarchy (`Rubik`, `Noto Sans Arabic`), and grammar/agreement correction.
- **Isolated Monetization**: Pro subscription removes ads only. 100% of correction features and engines remain free and offline for all users.

---

## Repository Architecture

```
Grammar_app/
├── android/                   # Native Android setup, ProcessTextActivity, MainActivity
├── dart_defines/              # Per-environment keys (grammar_fix.json)
├── docs/                      # Legal, licenses, setup, store, and business docs
├── lib/
│   ├── core/                  # Configuration, theme, play services, localizations
│   ├── design/                # White+Green tokens, typography, custom SVG icons
│   ├── features/
│   │   ├── ads/               # AdMob banners & interstitials (Pro disabled)
│   │   ├── correction/        # Repositories, Harper engine, Multilingual engine, UI
│   │   ├── feedback/          # Anonymous, zero-text feedback
│   │   ├── onboarding/        # Guest-first 2-screen onboarding
│   │   ├── settings/          # Dialects, custom dictionary, pack manager, legal links
│   │   ├── shell/             # Floating glass 2-tab navigation (Correct, Settings)
│   │   └── subscriptions/     # RevenueCat Pro purchase & restore
│   └── main.dart              # Guest-first initialization
├── ml/                        # ML schemas, evaluation runner, LiteRT-LM scripts
├── native/harper_bridge/      # Rust C-ABI wrapper for harper-core (16KB alignment)
├── test/                      # 65+ Unit tests, Widget tests, GEC fixtures
└── THIRD_PARTY_NOTICES.md     # Apache 2.0 & MIT license notices
```

---

## Build & Test Instructions

### Running Flutter Tests
```bash
flutter pub get
flutter test
```

### Running Static Analysis
```bash
flutter analyze
```

### Running with Dart Defines
```bash
flutter run --dart-define-from-file=dart_defines/grammar_fix.json
```

---

## Privacy Architecture

1. **Zero Text Telemetry**: User text is strictly confined to memory during correction.
2. **Crash Reporting**: Crashlytics and error logs are filtered to never contain user sentences.
3. **Optional Local Drafts**: Off by default. When enabled by user, stored in encrypted local storage on device.

---

## License & Attribution

- Built for **Mogate** (`com.mogate.grammarfix`).
- Harper engine: Licensed under Apache 2.0.
- Qwen3 model weights: Licensed under Apache 2.0.
- Full notices in [THIRD_PARTY_NOTICES.md](file:///c:/Code/Grammar_app/THIRD_PARTY_NOTICES.md).
