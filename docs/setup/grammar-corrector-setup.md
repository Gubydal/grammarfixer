# Grammar Corrector Setup & System Integration Guide

## 1. Overview

GrammarFix integrates into Android at three distinct integration touchpoints:
1. **Full-Featured Local Editor** (Flutter UI)
2. **Context Menu Action** (`ACTION_PROCESS_TEXT` - "Fix grammar")
3. **Continuous Typing System Integration**:
   - Android Text Services (`SpellCheckerService`)
   - Optional On-Device Grammar Keyboard (`InputMethodService`)

---

## 2. Setting Up Selected-Text Correction (`ACTION_PROCESS_TEXT`)

When a user selects text in any Android application (WhatsApp, Gmail, Chrome, Slack, Samsung Notes):
1. The system text-selection toolbar appears.
2. Tap **"Fix grammar"** (or tap three dots if overflowed).
3. `ProcessTextActivity` opens as a lightweight transparent modal over the current app.
4. GrammarFix applies the correction locally on device.
5. Tap **"Apply"** -> The corrected text replaces the selection in-place via `setResult(RESULT_OK, Intent().putExtra(EXTRA_PROCESS_TEXT, correctedText))` and immediately closes without opening the main app navigation or triggering paywalls.

---

## 3. Setting Up the System Grammar Checker

1. Open Android **Settings** -> **System** -> **Languages & Input** -> **Spell Checker** (or **Text Services**).
2. Select **GrammarFix** as the default spell and grammar checker.
3. Supported apps will now underline typos and show GrammarFix's instant suggestions directly in their text fields.

---

## 4. Setting Up the On-Device Grammar Keyboard

1. Open GrammarFix -> **Settings** -> **Writing Everywhere** -> **Grammar Keyboard** -> Tap **Set up**.
2. Tap **Open Settings** to open Android Input Method settings.
3. Toggle on **GrammarFix Keyboard**.
4. When typing, switch your keyboard using the keyboard switcher icon in the Android navigation bar.
5. Enjoy real-time debounced suggestion bubbles with 100% privacy and automatic sensitive field protection.
