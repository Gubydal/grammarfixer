# GrammarFix — ACTUAL REPOSITORY REPAIR PROMPT
## Based on direct inspection of grammarfixer-main.zip

Work on the existing GrammarFix repository contained in the current workspace.

This is NOT a rebuild.
This is NOT a redesign.
This is a deep implementation repair based on actual source-code audit and real-device test results.

The app already has a good white/green UI, guest-first flow, local correction UX, custom dictionary, Personal Style UI, AdMob, RevenueCat, and a useful base correction engine.

Preserve what is already good.

The job is to replace the current placeholder/scaffold integrations with real working implementations and make GrammarFix behave continuously while typing.

---

# 1. ACTUAL REPO FINDINGS — TREAT AS FACT

Before editing, inspect and confirm these files:

```text
lib/features/correction/presentation/cubits/correction_cubit.dart
lib/features/correction/presentation/pages/editor_page.dart
lib/features/correction/data/repositories/correction_repository.dart
lib/features/correction/data/repositories/model_pack_repository.dart
lib/features/correction/domain/services/harper_engine.dart
lib/features/correction/domain/services/multilingual_engine.dart
lib/features/correction/domain/services/typo_candidate_engine.dart
lib/features/correction/domain/services/correction_merger.dart
lib/features/settings/presentation/pages/settings_page.dart

android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/com/mogate/grammarfix/MainActivity.kt
android/app/src/main/kotlin/com/mogate/grammarfix/ProcessTextActivity.kt
android/app/src/main/kotlin/com/mogate/grammarfix/GrammarKeyboardService.kt
android/app/src/main/kotlin/com/mogate/grammarfix/GrammarSpellCheckerService.kt
android/app/src/main/res/xml/method.xml
android/app/src/main/res/xml/spellchecker.xml

native/harper_bridge/src/lib.rs
native/harper_bridge/Cargo.toml

ml/eval/evaluate_gec.py
ml/training/convert_to_tflite.py
```

The following problems exist in the inspected repository.

---

# 2. ROOT CAUSE — MAIN EDITOR IS NOT LIVE

`EditorPage._onTextChanged()` currently only calls:

```text
CorrectionCubit.updateText()
```

`CorrectionCubit.updateText()` only:

- updates `_currentInputText`;
- saves draft;
- emits `CorrectionEditing`.

It does NOT schedule or run correction.

Actual correction is only performed by:

```text
CorrectionCubit.runCorrection()
```

and the main CTA explicitly calls it.

Therefore the current:

```text
Auto-Fix Obvious Mistakes
```

setting is misleading.

The setting only affects what happens AFTER `runCorrection()` has already been manually triggered.

Fix this architecture.

---

# 3. ROOT CAUSE — PROCESS_TEXT PAGE EXISTS BUT IS NOT ROUTED

The repo contains:

```text
ProcessTextActivity.kt
ProcessTextPage.dart
```

and both use:

```text
com.mogate.grammarfix/process_text_channel
```

However the Flutter app's `MaterialApp` always chooses normal:

```text
OnboardingPage
or
MainShell
```

as home.

`ProcessTextPage` is not wired as the UI for the separate `ProcessTextActivity`.

This explains the real-device behavior:

```text
select text
→ choose GrammarFix
→ full app opens
→ selected text does not appear
```

Repair this properly.

Preferred solution:

Make `ProcessTextActivity` a lightweight NATIVE Android activity using the same native correction core described below.

Do not boot the entire Flutter app merely to process selected text.

Alternative is a separate Flutter entrypoint/route, but only use that if it is demonstrably reliable and fast.

The final behavior must return corrected text to the originating app.

---

# 4. ROOT CAUSE — KEYBOARD SETTINGS BUTTON USES URL_LAUNCHER WRONG

`settings_page.dart` currently attempts:

```dart
launchUrl(Uri.parse('android.settings.INPUT_METHOD_SETTINGS'))
```

and similarly:

```dart
launchUrl(Uri.parse('android.settings.TEXT_SERVICES_SETTINGS'))
```

This treats Android intent action strings like ordinary URI links.

That is why the button falls through to the manual-settings dialog.

Do NOT use `url_launcher` for Android Settings actions.

Create a native Android bridge such as:

```text
com.mogate.grammarfix/android_settings
```

with methods:

```text
openInputMethodSettings
showInputMethodPicker
getKeyboardStatus
getSpellCheckerStatus
openSpellCheckerSettingsIfSupported
```

Use real Android `Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)` for keyboard setup.

After returning to Flutter, query actual enabled state.

---

# 5. ROOT CAUSE — SYSTEM SPELL CHECKER IS TOKEN-ONLY

`GrammarSpellCheckerService.onGetSentenceSuggestionsMultiple()` currently calls:

```text
onGetSuggestions(textInfo, ...)
```

on the entire sentence.

`onGetSuggestions()` only checks a hardcoded typo map.

Therefore sentence grammar/context checking is NOT implemented.

Replace it with real sentence analysis through the shared correction core.

Return proper sentence offsets and lengths.

---

# 6. ROOT CAUSE — KEYBOARD USES A SEPARATE TINY HARDCODED ENGINE

`GrammarKeyboardService.kt` does NOT use:

- `CorrectionRepository`;
- Harper;
- multilingual model;
- Personal Style;
- the actual main correction pipeline.

It contains its own:

```text
keyboardTypos
contextualPhrases
```

maps.

It reads only:

```text
getTextBeforeCursor(60, 0)
```

and then shows a tappable suggestion.

This means the keyboard is effectively a separate toy correction engine.

Replace this duplication with a shared native correction core.

---

# 7. ROOT CAUSE — KEYBOARD DOES NOT AUTO-APPLY

`GrammarKeyboardService.addSuggestionButton()` only changes text when the user taps the suggestion.

The current Auto-Fix setting is not connected to the IME.

Connect Auto-Fix to the keyboard.

High-confidence objective corrections may auto-apply.

Every auto-apply must provide Undo.

---

# 8. ROOT CAUSE — QWEN/LITERT IS NOT ACTUALLY WIRED

`MultilingualEngine` invokes:

```text
MethodChannel('com.mogate.grammarfix/litert_lm')
```

with:

```text
isModelReady
generate
```

There is no matching handler for this channel in `MainActivity.kt`.

`MainActivity.kt` instead registers:

```text
com.mogate.grammarfix/multilingual_engine
```

with methods:

```text
isAvailable
correct
```

and the current `correct` implementation simply returns the original input text.

Therefore the described LiteRT/Qwen path is NOT working.

Implement one real, consistent channel/API.

Prefer to move the model runtime to a native shared core that Flutter, IME, ProcessText and SpellChecker can all use.

---

# 9. ROOT CAUSE — MODEL PACK DOWNLOAD IS SIMULATED

`ModelPackRepository.startDownload()` currently loops with delayed timers and then sets:

```text
multilingual_model_pack_installed = true
```

No model is downloaded.

`MainActivity.requestDownload` also just returns true.

This must NOT remain.

Implement real model delivery.

Use the existing approved Google Play on-demand delivery architecture if production-ready.

For local/dev APK testing, provide a clearly documented developer path to sideload/place the model asset without pretending it was downloaded from Play.

Do not mark model "installed" until:

- the actual model file exists;
- size is plausible;
- checksum/version is validated;
- runtime can initialize it.

---

# 10. ROOT CAUSE — ML CONVERSION SCRIPT IS A PLACEHOLDER

`ml/training/convert_to_tflite.py` currently only prints simulated conversion steps and writes a text manifest file.

It does NOT convert or quantize a model.

Replace it with either:

A. a real reproducible official conversion pipeline;

or

B. remove the fake converter and document the exact official preconverted compatible model artifact used by the app.

Do not keep fake "conversion complete" output.

---

# 11. ROOT CAUSE — ML EVALUATOR ALWAYS PASSES

`ml/eval/evaluate_gec.py` currently effectively does:

```text
passed = len(cases)
```

and reports 100% without running inference.

This is invalid QA.

Replace with a real evaluator that:

- invokes actual local model output or saved benchmark output;
- compares required/optional/forbidden edits;
- reports pass/fail honestly;
- measures false positives.

Never print "Zero-Leakage Privacy Audit PASSED" from an evaluator that did not perform network inspection.

---

# 12. ROOT CAUSE — HARPER RUST BRIDGE IS ALSO A STUB

`native/harper_bridge/src/lib.rs` declares a dependency on `harper-core`, but:

```rust
harper_lint_json(...)
```

currently constructs:

```rust
let issues = Vec::new();
```

It does not actually invoke Harper linting.

This must be fixed.

Implement real Harper integration in Rust.

The native bridge must:

- create/configure Harper document/linter;
- select English dialect;
- add user dictionary terms;
- lint input;
- map real lint spans;
- return suggestions;
- return category/message;
- preserve UTF-8 offsets correctly for Dart/Kotlin consumers.

Do not claim Harper Native until this works.

---

# 13. ROOT CAUSE — HARPER NATIVE BUILD IS NOT AUTOMATED

The repo contains no committed `jniLibs` Harper binary and the Android Gradle file does not build the Rust bridge.

Create a reproducible build integration.

Options:

- Gradle task invoking cargo-ndk;
- documented prebuild step wired into CI/release;
- another deterministic supported native-build mechanism.

Required ABIs should match the actual release strategy.

Ensure 16 KB page alignment.

The release build must fail if native Harper is expected but missing.

Do NOT silently fall back in production without surfacing engine diagnostics during QA.

---

# 14. BUILD A SHARED NATIVE GRAMMAR CORE

The biggest architectural repair:

Create a shared Android-native layer, conceptually:

```text
GrammarCore
```

that can be called from:

- Flutter main editor;
- GrammarKeyboardService;
- GrammarSpellCheckerService;
- ProcessTextActivity.

Do not maintain four separate grammar implementations.

Concept:

```text
GrammarCore
├── EnglishTypoEngine
├── EnglishContextRules
├── HarperNative
├── LocalContextModel
├── ProtectedSpanDetector
├── CorrectionMerger
├── ConfidencePolicy
└── WritingCommandEngine
```

Flutter remains responsible for UI/state.

Native core owns correction execution used system-wide.

---

# 15. FLUTTER BRIDGE

Create a clear native channel:

```text
com.mogate.grammarfix/grammar_core
```

Methods:

```text
correct
quickCheck
rewrite
isContextModelReady
getEngineDiagnostics
```

Example input:

```json
{
  "text": "...",
  "language": "en",
  "mode": "correct",
  "includeContextModel": true,
  "dialect": "us"
}
```

Return structured JSON:

```text
correctedText
issues[]
engineDiagnostics
latencyMs
```

Do not expose user text in diagnostics/logs.

---

# 16. REAL-TIME MAIN EDITOR

Refactor `CorrectionCubit`.

Add:

```text
onTextChangedLive(...)
```

or equivalent.

Use timers/debounce.

Suggested pipeline:

## immediately after word boundary

run:

```text
quickCheck
```

for:

- typo;
- Harper deterministic grammar;
- context rules.

## after 400–600 ms idle

run:

```text
full contextual correction
```

if model ready.

## after sentence-ending punctuation

run sentence contextual pass.

Cancel stale requests.

---

# 17. DO NOT ENTER FULL REVIEW MODE ON EVERY KEYSTROKE

Current app switches between:

```text
CorrectionEditing
CorrectionReview
```

Keep manual full review for the Correct button.

For live mode introduce a lightweight state such as:

```text
LiveCorrectionState
```

or extend Editing state with:

```text
liveIssues
lastAutoFix
isLiveChecking
```

Do not replace the entire editor with `ReviewModeView` while user is typing.

Live corrections appear inline/compactly.

---

# 18. AUTO-FIX POLICY

When:

```text
PersonalStyleRepository.isAutoFixEnabled == true
```

automatically apply only safe high-confidence objective fixes.

Eligible initially:

```text
obvious typo
duplicate letter typo
clear apostrophe correction
clear subject/verb agreement
clear auxiliary/verb-form rule
deterministic homophone context
duplicate punctuation/spacing
```

Not eligible:

```text
ambiguous pronoun
style rewrite
Professional/Friendly rewrite
uncertain semantic word choice
whole-message rewrite
```

---

# 19. AUTO-FIX EXPLANATION

After auto-fix display existing-style compact explanation:

```text
went → gone
Verb tense
Undo
```

No Correct press required.

Keep this visible briefly or until next edit.

Do not interrupt keyboard focus.

---

# 20. RETROACTIVE CONTEXT CORRECTION — REQUIRED

Must detect previous valid word after later context arrives.

Examples:

```text
Your
```

No correction necessarily.

After:

```text
Your going
```

re-evaluate:

```text
Your → You're
```

Likewise:

```text
I need too
```

may remain uncertain.

After:

```text
I need too go
```

correct:

```text
too → to
```

The correction span may be several characters behind the cursor.

---

# 21. ENGLISH CONTEXT RULES — EXPAND PROPERLY

The current fallback Harper rules already contain:

```text
their/there + going/coming/leaving...
your + right/welcome...
better then...
```

but coverage is too narrow.

Create a dedicated tested EnglishContextRules module.

Must cover safely:

```text
their / there / they're
your / you're
to / too / two
its / it's
then / than
were / we're / where
whose / who's
accept / except
affect / effect
loose / lose
whether / weather
```

Do not blindly replace string pairs.

Use context patterns.

Required fixtures:

```text
Their going home.
→ They're going home.

Your going to like it.
→ You're going to like it.

I need too go now.
→ I need to go now.
```

No-change:

```text
Their house is nearby.
Your phone is ringing.
I ate too much.
Two people are here.
The dog wagged its tail.
```

---

# 22. INSTALLED APK VS SOURCE MISMATCH CHECK

The inspected source already contains a fallback rule for:

```text
Their going
```

but the owner's real-device build reported:

```text
No issues found
```

Therefore explicitly determine whether:

- the installed APK was stale;
- native Harper stub was being loaded;
- a different source revision produced the APK;
- the rule never entered the runtime path.

At startup in DEBUG builds expose non-sensitive diagnostics:

```text
HarperNative: available / unavailable
ContextModel: ready / unavailable
CorrectionCoreVersion: ...
```

Never show text.

Build a fresh APK from this exact working tree before owner testing.

---

# 23. KEYBOARD — USE SHARED CORE

Replace `keyboardTypos` and `contextualPhrases` as the primary engine.

The IME should call:

```text
GrammarCore.quickCheck()
```

using current sentence context.

The hardcoded map may remain only as an emergency no-core fallback.

---

# 24. KEYBOARD CONTEXT WINDOW

Replace:

```text
getTextBeforeCursor(60, 0)
```

with a bounded but meaningful window such as:

```text
500–1500 chars before cursor
and a modest after-cursor window
```

Then extract:

- current sentence;
- previous sentence where useful;
- selection.

Do not process full chat history.

---

# 25. KEYBOARD AUTO-APPLY

When Auto-Fix is enabled:

for safe high-confidence fix:

1. verify source span still matches;
2. begin batch edit;
3. replace exact span;
4. preserve cursor;
5. end batch edit;
6. show explanation + Undo.

Use `InputConnection`.

Do not append an extra space incorrectly.

Current implementation:

```text
commitText("$suggestion ", 1)
```

can introduce unwanted spacing.

Fix this.

---

# 26. KEYBOARD UNDO

Suggestion strip after auto-fix:

```text
Your → You're · Word choice     Undo
```

Store:

```text
original
replacement
range
editor generation
```

Undo only if source still matches expected replacement.

---

# 27. KEYBOARD SETUP NATIVE BRIDGE

Implement native calls.

`openInputMethodSettings`:

```kotlin
startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
```

with resolution safeguards.

`showInputMethodPicker`:

```kotlin
val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
imm.showInputMethodPicker()
```

`getKeyboardStatus`:

check:

```text
InputMethodManager.inputMethodList
enabledInputMethodList
```

for GrammarFix service ID.

Return:

```text
installed
enabled
active/default where reliably detectable
```

---

# 28. SETTINGS UX

Replace current failing `url_launcher` logic.

Use:

```text
WRITING EVERYWHERE

Grammar Keyboard
Best experience for live correction
Not enabled             [Enable]

System Grammar Checker
Extra support in compatible editors
Available               [Set up]

Select text → GrammarFix
Quickly correct selected text
[How it works]
```

After enable:

```text
Grammar Keyboard
Enabled ✓               [Choose]
```

If selected/current:

```text
Active ✓
```

Manual vendor instructions are last resort only.

---

# 29. NO ACCESSIBILITY SERVICE

Do not implement AccessibilityService.

Do not request:

```text
BIND_ACCESSIBILITY_SERVICE
SYSTEM_ALERT_WINDOW
usage access
```

GrammarFix should rely on:

```text
InputMethodService
PROCESS_TEXT
SpellCheckerService
```

---

# 30. PROCESS_TEXT — IMPLEMENT FOR REAL

Preferred:

Convert `ProcessTextActivity` from a FlutterActivity into a small native Activity/Dialog-themed Activity.

Read:

```text
Intent.EXTRA_PROCESS_TEXT
Intent.EXTRA_PROCESS_TEXT_READONLY
```

Immediately run shared GrammarCore.

Show:

```text
Fix Grammar

corrected preview
issue summary

Apply / Cancel
```

For writable input:

return:

```text
Intent.EXTRA_PROCESS_TEXT = corrected text
RESULT_OK
```

Then `finish()`.

For read-only:

Copy.

No full app.

---

# 31. SPELL CHECKER — USE SHARED CORE

Replace hardcoded `quickTypos` as primary behavior.

`onGetSuggestions` may use lightweight word spelling.

`onGetSentenceSuggestionsMultiple` must:

- call sentence-level quick grammar core;
- map issue offsets into `SentenceSuggestionsInfo`;
- avoid pretending a full sentence is one word;
- be thread-safe.

Do not attempt creative rewrite through SpellCheckerService.

---

# 32. REAL LOCAL MODEL IMPLEMENTATION

Implement actual on-device model inference.

Use the currently selected supported LiteRT-LM-compatible Qwen model artifact.

Do not claim it works until:

```text
actual model exists
runtime initializes
real generate() works
```

Create one native runtime manager:

```text
LocalContextModelManager
```

Responsibilities:

```text
model file validation
one-time initialization
bounded inference queue
cancel/stale generation handling
thermal/memory failure handling
model version
```

---

# 33. MODEL PACK STATE MUST REFLECT REALITY

`ModelPackRepository` must query native state instead of SharedPreferences alone.

Installed means:

```text
actual model present
+
checksum/version valid
+
runtime recognizes it
```

SharedPreferences may cache metadata but is not authoritative.

---

# 34. MODEL PACK FOR DEV APK

Because Google Play Asset Delivery cannot be fully exercised from an arbitrary locally sideloaded APK the same way as production Play delivery:

support a documented development test mode.

Options:

- dev model copied through adb to app-specific storage;
- dev-only bundled tiny/smaller test model;
- locally installed asset-pack test path.

Do not fake a 475 MB download in production code.

---

# 35. WRITING TOOLS ICON — ADD NOW

Add a small wand/writing-tools icon in the GrammarFix keyboard suggestion bar.

Tap opens compact popup:

```text
Writing tools

Professional
Friendlier
Clearer
Shorter
Fix grammar
Rewrite
```

Exactly six initially.

---

# 36. WRITING TOOL TARGET

Use:

1. current selection if selection exists;
2. otherwise current paragraph/message around cursor.

Do not read an entire conversation.

Bound the text.

---

# 37. WRITING TOOL PREVIEW

Creative commands must never silently replace.

Example:

```text
Professional

Could you please send me the report?
I need it by the end of today.

Replace
Cancel
```

Everything local.

---

# 38. WRITING COMMAND PROMPTS

Professional:

> Rewrite the text in a professional, natural tone. Preserve all facts, names, numbers, dates, requests and source language. Add no new information. Return only rewritten text.

Friendlier:

> Make the message warmer and friendlier while preserving meaning and details. Avoid excessive enthusiasm. Return only rewritten text.

Clearer:

> Improve clarity and structure with minimal wording changes. Preserve facts and source language. Return only rewritten text.

Shorter:

> Make the message more concise while preserving all important facts and requests. Return only rewritten text.

Fix grammar:

> Correct grammar, spelling, punctuation and context-dependent word choice with the smallest necessary edits. Preserve tone and meaning.

Rewrite:

> Rewrite naturally while preserving meaning, facts, tone intent and source language. Do not add information.

---

# 39. SLASH COMMANDS — OPTIONAL POWER FEATURE

Support:

```text
/professional
/friendly
/clearer
/shorter
/fix
/rewrite
```

When typed at start of current message:

show action suggestion.

Do not execute automatically.

---

# 40. NO MODEL PACK = CORE STILL WORKS

Without large model:

English must still have excellent:

- typos;
- Harper rules;
- homophone/context rules;
- punctuation;
- agreement;
- tense.

Writing commands requiring generation can ask user to install Offline Writing AI.

No cloud fallback.

---

# 41. REAL HARPER NATIVE IMPLEMENTATION

Do not leave `issues = Vec::new()`.

Use actual `harper-core`.

Follow the current Harper API for the pinned revision/version.

Map:

```text
lint span
suggestion
message
category
```

to C/JNI-safe structured results.

Add Rust tests with real sentences:

```text
He don't understand.
I have went there.
She ate a apple.
```

---

# 42. DART FALLBACK

Keep current Dart rule engine as:

```text
EmergencyFallbackEnglishEngine
```

not something called Harper if Harper native failed.

Engine diagnostics should accurately name:

```text
Harper Native
or
Dart Rules Fallback
```

This matters for QA.

---

# 43. SHARE ENGINE WITH KOTLIN

Because IME/SpellChecker/ProcessText run natively, expose real Harper to Kotlin too.

Preferred:

- extend the Rust cdylib with JNI exports;
- create `HarperNative.kt`;
- or another robust native binding.

Do not spin up a Flutter engine every time the keyboard checks a word.

That would be heavy and unreliable.

---

# 44. PERSONAL STYLE SHARED STORAGE

Keyboard and Flutter must read the same:

```text
autoFixEnabled
privateMode
dialect
style preferences
custom words
```

Use a shared local settings representation accessible safely from Kotlin and Dart.

Do not duplicate settings with unsynchronized values.

Migration from current SharedPreferences must preserve existing user choices.

---

# 45. PRIVATE MODE

When Private Mode:

- no Personal Style learning;
- no retained keyboard correction history;
- no full-message history;
- correction still works;
- model prompts remain ephemeral.

Sensitive fields always behave at least as strictly as Private Mode.

---

# 46. PROTECTED SPANS

Preserve current no-damage behavior.

Must not alter:

```text
john@example.com
https://mogate.tech/privacy
Flutter 3.35.2
SKU-1204
$39.99
ChatGPT
OpenAI
code
hashtags
usernames
```

Run protected span logic before model correction.

Validate protected spans after model output.

---

# 47. CONTEXTUAL MODEL MINIMAL-EDIT POLICY

Do not let Qwen rewrite aggressively during automatic checking.

System instruction:

> Correct only necessary grammar, spelling, punctuation, agreement, tense and context-dependent word-choice errors. Preserve meaning, tone, informality, names, formatting and source language. Do not translate. Do not improve style unless the caller explicitly requests a rewrite command.

---

# 48. CROSS-SENTENCE AMBIGUITY

For:

```text
Sarah came to the office. He brought the documents.
```

do not auto-change.

If the local model flags it:

surface:

```text
Possible pronoun mismatch
```

as a non-auto-fixable suggestion.

No hallucinated referent.

---

# 49. LIVE CHECK CANCELLATION

Every check gets:

```text
revision/generation
source hash
```

Before applying:

re-read source.

If stale:

discard.

This already partially exists in `CorrectionRepository` via revisions; extend the same safety to editor/IME/native model.

---

# 50. PERFORMANCE

Do not run Qwen on every key.

Suggested:

```text
letter:
no heavy model

space:
fast English rules

400–600 ms idle:
context model if installed

sentence punctuation:
context model

writing tool:
explicit model
```

IME remains responsive even if model is loading.

---

# 51. TEST ACTUAL OWNER CASES

Create a dedicated fixture:

```text
test/fixtures/owner_acceptance.json
```

Must include:

```text
I has a car.
I have went there before.
The dogs is outside.
She will came tomorrow.
hellooooo how are youuu
definatelyyy
recieveee
whatt happened
thsi is good
I dont knwo whatt happend
Their going home.
Your going to like it.
I need too go now.
Sarah came to the office. He brought the documents.
Email Ahmed at ahmed@example.com.
Visit https://mogate.tech/privacy
Flutter 3.35.2
SKU-1204 costs $39.99.
ChatGPT and OpenAI are product names.
hey bro idk what happened lol 😂
hey bro i dont know what happened
```

Define:

```text
required edits
optional warnings
forbidden edits
```

---

# 52. FIX THE TEST SUITE HONESTLY

Do not keep tests that only validate UI labels or hardcode 100% pass.

Add actual tests for:

- live debounce;
- auto-fix;
- Undo;
- context rules;
- false-positive clean text;
- ProcessText Activity;
- IME service discovery;
- keyboard retroactive replacement;
- spell checker sentence offsets;
- model-ready real inference when model fixture exists;
- model-missing fallback.

---

# 53. REAL ML EVALUATION

Rewrite `ml/eval/evaluate_gec.py`.

It should not report pass without output.

Input:

```text
fixture JSON
+
actual inference output JSON
```

or invoke a local runtime where feasible.

Report:

```text
required edit recall
false-positive rate
forbidden edit violations
exact/accepted output rate
latency
```

Never fake 100%.

---

# 54. NETWORK PRIVACY TEST

Use a unique synthetic marker:

```text
GRAMMARFIX_PRIVATE_TEST_7F92A
```

Run through:

- main editor;
- keyboard;
- PROCESS_TEXT;
- Professional rewrite.

Capture outgoing network.

Confirm marker absent.

Document:

```text
docs/privacy/local-processing-verification.md
```

Do not claim this test passed unless actually run.

---

# 55. SETTINGS STATUS

Use actual native status.

Do not let Flutter say Enabled merely from local bool.

Keyboard status source of truth:

Android IME manager.

Model status source of truth:

actual model storage/runtime.

Spell checker source of truth:

TextServicesManager where API permits.

---

# 56. SYSTEM SPELL CHECKER EXPECTATION

Keep this feature secondary.

Some host apps/OEMs may not surface the system spell checker consistently.

Do not promise universal correction.

The GrammarFix keyboard is the reliable system-wide experience.

---

# 57. NO ACCESSIBILITY

Verify manifest does not contain:

```text
BIND_ACCESSIBILITY_SERVICE
SYSTEM_ALERT_WINDOW
PACKAGE_USAGE_STATS
```

for grammar behavior.

Do not add them.

---

# 58. ADS

Never show ads:

- inside IME;
- ProcessText activity;
- writing command popup;
- spell checker;
- correction overlays/sheets.

Do not pass writing context to AdMob.

Keep existing passive-app ad policy otherwise.

---

# 59. README CLAIMS MUST MATCH REAL CODE

Current README overstates:

```text
Harper native
Qwen LiteRT-LM
Play on-demand model
```

when actual repo contains stubs/placeholders.

After implementation:

update README truthfully.

If a feature remains incomplete:

say it is incomplete.

Do not leave claims that tests do not prove.

---

# 60. BUILD INTEGRATION

Run:

```text
Rust tests
native build
Flutter analyze
Flutter tests
Android unit/instrumentation tests
```

If Flutter SDK is unavailable in the current environment, do not fabricate results.

Use an environment with Flutter/Android tooling for final build.

---

# 61. BUILD A FRESH APK — MANDATORY

After implementation and tests:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Also:

```bash
flutter build appbundle --release
```

where configuration permits.

Do NOT give the owner an old APK.

Build from the exact repaired commit/working tree.

---

# 62. APK REPORT

Provide:

```text
APK path
APK size
versionName
versionCode
SHA-256
git commit / source revision if available
build command
```

If a physical/emulated Android device is connected:

install the APK and run the owner acceptance flow.

---

# 63. DEVICE ACCEPTANCE — MAIN EDITOR

Auto-Fix ON.

Type without pressing Correct:

```text
I has a car.
```

Expected automatic fix + explanation + Undo.

Then:

```text
Your going to like it.
```

Expected retroactive context fix/suggestion.

Then:

```text
I need too go now.
```

Expected context fix/suggestion.

No Correct tap.

---

# 64. DEVICE ACCEPTANCE — KEYBOARD SETUP

Fresh install.

Tap:

```text
Settings
→ Grammar Keyboard
→ Enable
```

Expected:

real Android input-method settings opens.

GrammarFix appears.

User enables it.

Return.

App detects:

```text
Enabled ✓
```

Tap:

```text
Choose
```

System IME picker appears.

No manual vendor dead-end in normal flow.

---

# 65. DEVICE ACCEPTANCE — KEYBOARD CONTEXT

In an external editor type:

```text
Your
```

then:

```text
 going
```

GrammarFix must reconsider `Your`.

With Auto-Fix ON and safe confidence:

```text
You're going
```

Show:

```text
Your → You're
Undo
```

Also:

```text
I need too go
→ I need to go
```

---

# 66. DEVICE ACCEPTANCE — PROCESS_TEXT

External app:

type:

```text
I have went there.
```

Select.

Choose GrammarFix.

Expected:

- compact correction UI;
- selected text already populated;
- corrected preview;
- Apply returns to source;
- source now reads:

```text
I have gone there.
```

No retyping.

---

# 67. DEVICE ACCEPTANCE — WRITING TOOL

GrammarFix keyboard:

```text
hey can you send the report i need it today
```

Tap wand → Professional.

Local model preview.

Tap Replace.

Text replaced in same host app.

No cloud request containing message.

---

# 68. FINAL REPORT — ROOT CAUSES

When done, explicitly report how each audited placeholder was replaced:

```text
main editor manual-only trigger
url_launcher Android settings misuse
ProcessText routing
keyboard hardcoded mini-engine
SpellChecker token-only logic
LiteRT channel mismatch
fake model download
fake conversion script
fake evaluator
stub Harper bridge
native build integration
```

---

# 69. FINAL REPORT — ENGINE DIAGNOSTICS

State:

```text
English fast engine:
actual implementation

Harper:
actual native implementation/version

Context model:
actual model/runtime/version

Model delivery:
actual mechanism

Keyboard:
shared core status

Spell checker:
shared core status
```

No aspirational wording.

---

# 70. FINAL PRINCIPLE

The repaired app must behave like:

```text
type normally
↓
fast local correction happens automatically
↓
context from later words can repair earlier words
↓
explanation + Undo
```

Across Android:

```text
GrammarFix Keyboard
→ reliable live correction

Select text → GrammarFix
→ compact correction and return

Writing tools
→ local private rewrite
```

And the implementation must finally match the product promise:

> GrammarFix is local, contextual, continuous, and private.
