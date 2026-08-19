# GrammarFix Setup & Developer Guide

## Prerequisites

1. **Flutter SDK**: 3.29.0 or higher
2. **Android SDK**: compileSdk 37, targetSdk 36, minSdk 26
3. **Rust Toolchain**: 1.80+ with `cargo-ndk` for native ARM64/x86_64 compilation
4. **Dart Defines**: `dart_defines/grammar_fix.json`

---

## Quick Start

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Build Rust native C-ABI bridge (optional for simulator/host tests)
cd native/harper_bridge
cargo ndk -t arm64-v8a -t x86_64 -o ../../android/app/src/main/jniLibs build --release
cd ../..

# 3. Run all tests
flutter test

# 4. Launch app with Mogate configuration
flutter run --dart-define-from-file=dart_defines/grammar_fix.json
```
