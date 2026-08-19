# Grammar Corrector — Full Production Build Prompt

Build a production-ready Android Flutter application for **Mogate** using:

`https://github.com/Gubydal/Flutter_template_v2`

Working product name:

**GrammarFix**

Working slug:

`grammar-fix`

Android package:

`com.mogate.grammarfix`

Supabase schema:

`app_grammar_fix`

Legal URLs:

- `https://grammar-fix.mogate.tech/privacy`
- `https://grammar-fix.mogate.tech/terms`
- `https://grammar-fix.mogate.tech/delete-account`

Public contact:

`mogatebusiness@gmail.com`

The final product must be a **very simple, privacy-first grammar corrector** that works locally on the phone.

The core product promise is:

> Paste or select text, correct it instantly, keep your writing on your device.

No cloud text processing.

No Gemini.

No OpenAI.

No paid grammar API.

No server-side LLM.

No server-side document processing.

No custom keyboard in v1.

The app must work completely offline after any optional multilingual model pack has been downloaded once.

---

# 1. PRIMARY PRODUCT RULE

Keep the app narrow.

The user should be able to do three things extremely well:

```text
1. Paste/type text → Correct
2. Select text in another Android app → Fix grammar
3. Share text to this app → Correct and copy/share back
```

Do not turn this into:

- a notes app
- a document editor
- an email client
- a writing chatbot
- a translation app
- a plagiarism checker
- an AI detector
- a citation tool
- a document scanner
- a cloud writing workspace
- a custom keyboard

The product must feel lighter and faster than a large writing suite.

---

# 2. TEMPLATE RULE

Start from:

`https://github.com/Gubydal/Flutter_template_v2`

Use the template bootstrap mechanism for a new app.

Preserve useful infrastructure:

- BLoC/Cubit architecture
- design tokens/components where appropriate
- Settings shell
- RevenueCat infrastructure
- AdMob + UMP infrastructure
- feedback infrastructure
- review/update services
- localization infrastructure
- legal URL handling
- Android release tooling
- 16 KB checks

However, this app must have its own visual identity.

Do not inherit old VidBrief colors.

Do not create a login gate.

Never use:

- Riverpod
- Provider
- GetX

---

# 3. GUEST-FIRST — NO SIGN-IN REQUIRED

Authentication is NOT required for this app.

The user must be able to use every correction feature without creating an account.

First-run flow should be extremely short.

Recommended:

```text
Privacy-first grammar correction
Everything runs on your phone.

[ Start as guest ]
```

After the user taps **Start as guest**:

open the editor immediately.

Do not show:

- email
- password
- Google Sign-In
- account creation

before the product.

Do not repeatedly ask the guest to sign in later.

All features work for guests.

---

# 4. SUPABASE — VERY NARROW USE

Mogate already has a Supabase account with multiple app projects.

Never create or modify another app's schema.

Use only the explicitly configured project for this app.

Use schema:

`app_grammar_fix`

Supabase is NOT used for:

- correction text
- selected text
- clipboard contents
- writing history
- custom dictionary
- multilingual model input
- correction results

User writing must never be uploaded to Supabase.

If feedback is retained from the template, Supabase may store only anonymous feedback fields such as:

```text
id
rating
message
app_version
created_at
```

The feedback UI must warn:

> Please don't include text you are correcting or other private information.

No authentication is required for feedback.

Core correction must work if Supabase is unavailable.

---

# 5. PRIVACY ABSOLUTE RULE

User writing must never leave the device.

This includes text from:

- editor
- clipboard paste
- ACTION_PROCESS_TEXT
- Android Share
- multilingual model
- Harper

Never send writing to:

- Supabase
- AdMob
- RevenueCat
- analytics
- crash logs
- feedback automatically
- any AI API
- any backend

Never log complete user text in production.

Never put input text into exceptions, analytics events, breadcrumbs, or remote logs.

---

# 6. CORE ENGINES

The app has two correction engines.

```text
English
→ Harper

Validated non-English languages
→ local multilingual model
```

Both run on-device.

---

# 7. HARPER — ENGLISH ENGINE

Use:

`https://github.com/Automattic/harper`

Harper is the primary English grammar/spelling/style engine.

Pin a reviewed commit/release rather than tracking `master` blindly.

Harper is Apache-2.0.

Preserve required attribution.

Use `harper-core` rather than a remote API.

Do not call Harper's website or any external service.

---

# 8. HARPER NATIVE INTEGRATION

Preferred production architecture:

```text
Flutter
↓ Dart FFI
small Rust C-ABI wrapper
↓
harper-core
```

Do not run a local HTTP server.

Do not spawn a CLI process.

Do not require Node.js at runtime.

Create a small native module, for example:

```text
native/harper_bridge/
├── Cargo.toml
├── src/lib.rs
└── include/harper_bridge.h
```

Expose only the narrow operations the Flutter app needs.

Conceptually:

```text
initialize(dialect, config)
lint(text)
applySuggestion(text, lintId, suggestionIndex)
addUserWord(word)
removeUserWord(word)
```

Returning lint results as serialized JSON is acceptable if the boundary remains simple and tested.

Avoid a huge generated API surface.

---

# 9. HARPER BUILD

Use current stable Rust.

Use Android NDK-compatible Rust targets.

Build native libraries for the actual Android ABIs supported by the app.

At minimum test:

- arm64-v8a
- emulator ABI used by CI/testing

Only include additional ABIs when they are genuinely supported by current Play/device strategy.

Integrate native build reproducibly into Android/CI.

Do not require developers to manually copy `.so` files after every build.

Document the Rust setup.

---

# 10. HARPER 16 KB

Native Harper/Rust libraries must pass current Android 16 KB page-size compatibility requirements.

Run the project's 16 KB release checker against the real release AAB.

Do not assume Rust output is compliant without testing.

---

# 11. ENGLISH DIALECTS

Expose only useful English options.

Settings:

```text
English variant
- American
- British
- Canadian
- Australian
```

If Harper currently supports an additional well-tested English variant, it may be included.

Default from device locale where practical.

Do not ask on first launch unless necessary.

---

# 12. HARPER USER DICTIONARY

Support a local custom dictionary.

User can add words such as:

- names
- brands
- technical terms

Actions:

```text
Add to dictionary
Remove from dictionary
```

Store locally only.

Do not sync it.

Provide a simple dictionary management page in Settings.

---

# 13. MULTILINGUAL ENGINE

English must not require the large model.

Multilingual correction is an optional offline pack.

Initial validated languages:

```text
Arabic
French
Spanish
German
Portuguese
Italian
```

English remains Harper-first.

Do not advertise every language that the base model theoretically understands.

Only advertise languages that pass the app's correction-quality fixtures.

---

# 14. MULTILINGUAL MODEL

Use a small permissively licensed multilingual model suitable for mobile.

Primary starting model:

`Qwen/Qwen3-0.6B`

Use an Android-ready quantized LiteRT-LM artifact when compatible.

Preferred initial target:

```text
Qwen3-0.6B
mixed INT4
short context optimized for correction
```

Pin exact model artifact/hash/license in documentation.

Do not silently switch models between builds.

---

# 15. WHY THE MODEL IS OPTIONAL

Do not bundle ~500 MB of model weights in the initial app install.

The base app should remain small.

English works immediately after installation.

The multilingual model is downloaded only when the user asks for a supported non-English language or explicitly installs it in Settings.

---

# 16. MULTILINGUAL PACK DELIVERY

Use Google Play-hosted on-demand delivery.

Production preference:

1. use stable Google Play large-asset/model delivery available to normal Android apps;
2. package the quantized model as an on-demand model/asset pack;
3. do not host the model on Mogate infrastructure;
4. do not require a CDN;
5. do not download model weights from a random third-party URL at runtime.

If current **Play for On-device AI** is still beta at implementation time, prefer a stable Play Asset Delivery / Play Feature Delivery route unless the beta is explicitly approved for production.

The model file contains data only, not executable code.

---

# 17. MODEL PACK UX

When user first needs multilingual correction:

show a compact sheet.

Example:

**Download Offline Language Pack**

> Correct Arabic, French, Spanish, German, Portuguese and Italian entirely on your phone.

Display:

- approximate download size from actual built artifact
- free storage requirement
- privacy statement

Actions:

```text
Download
Not now
```

Do not auto-download hundreds of MB without explicit action.

---

# 18. MODEL DOWNLOAD STATE

Implement real states:

```text
notInstalled
checking
queued
downloading
paused
installed
updateAvailable
failed
removing
```

Show real progress from Play APIs.

Support:

- cancellation where supported
- resume/retry
- app backgrounding
- process death recovery

Do not fake percentage progress.

---

# 19. MODEL PACK STORAGE

Before starting model download:

check available storage.

Leave a safe margin beyond the compressed download size because installed model/runtime buffers need more space.

If insufficient:

show:

> Not enough storage for the offline language pack.

Do not crash or partially corrupt installation state.

---

# 20. REMOVE LANGUAGE PACK

Settings must include:

```text
Offline language pack
Installed · ~X MB
[ Remove ]
```

Removing the pack must:

- release its local storage
- keep English Harper working
- keep app settings
- not delete user dictionary

---

# 21. LOCAL LLM RUNTIME

Use current stable **LiteRT-LM** for Android where compatible with the chosen Qwen artifact.

Integrate it in native Android/Kotlin behind a narrow Flutter platform channel.

Concept:

```text
Flutter CorrectionRepository
   ↓
MethodChannel
   ↓
Kotlin MultilingualGrammarEngine
   ↓
LiteRT-LM
   ↓
Qwen3-0.6B model pack
```

Do not put inference logic throughout Flutter widgets.

---

# 22. MODEL INFERENCE CONFIG

Grammar correction is not a reasoning/chat task.

Use non-thinking mode.

Keep context deliberately small.

Recommended initial target:

```text
context: ~2048 tokens
thinking: off
temperature: as deterministic as supported
sampling: restrained
max output: bounded relative to input
```

Do not allocate 32K context for a paragraph correction.

---

# 23. MULTILINGUAL SYSTEM INSTRUCTION

The model instruction must be narrow.

Concept:

> Correct grammar, spelling, punctuation, agreement, and obvious word-form errors. Preserve the original language, meaning, tone, names, numbers, formatting, and level of formality. Make the minimum necessary edits. Never translate. Never explain. Return only the corrected text. If the text is already correct, return it unchanged.

Do not ask it to:

- improve creativity
- make writing more professional
- change tone
- summarize
- expand
- translate

The model is a correction engine, not a chatbot.

---

# 24. LLM OUTPUT DEFENSES

Never trust model output blindly.

Validate:

- output is non-empty unless input was empty
- output is valid Unicode
- output length ratio is reasonable
- output language is consistent with input
- no obvious explanation prefix was added
- no markdown code fence was added
- no translation occurred

If output is unsafe/malformed:

return original text and show a retry option.

Do not destroy user's text.

---

# 25. LANGUAGE IDENTIFICATION

Use local on-device language identification.

Preferred:

Google ML Kit Language Identification using its bundled/on-device path where current implementation allows it without remote text processing.

It may be wrapped through a small native Android service.

Language detection text must remain on-device.

Do not use a cloud language-detection API.

Auto detection should return:

```text
languageCode
confidence
```

If confidence is low:

show a small language selector rather than guessing aggressively.

---

# 26. LANGUAGE ROUTING

Default editor mode:

`Auto`

Routing:

```text
English confidently detected
→ Harper

Validated non-English language detected
AND multilingual pack installed
→ local Qwen

Validated non-English language detected
AND pack missing
→ offer language-pack download

Unknown / low confidence
→ ask user to choose language
```

Never silently send anything to cloud as fallback.

---

# 27. RTL / ARABIC

Arabic support is a product requirement.

Editor and results must support true RTL.

The document direction is based on corrected text/language, not only app locale.

Use direction-aware layout.

Test:

- Arabic only
- Arabic + English brand names
- Arabic + numbers
- Arabic + URLs
- Arabic punctuation
- mixed Arabic/Latin text

Do not reverse numbers or URLs incorrectly.

---

# 28. MULTILINGUAL QUALITY GATE

Create a versioned correction fixture corpus for each advertised language.

At minimum:

```text
test/fixtures/gec/en.json
test/fixtures/gec/ar.json
test/fixtures/gec/fr.json
test/fixtures/gec/es.json
test/fixtures/gec/de.json
test/fixtures/gec/pt.json
test/fixtures/gec/it.json
```

Each fixture contains:

```text
id
input
acceptedOutputs[]
category
notes
```

Categories should include:

- spelling
- punctuation
- agreement
- verb form
- article/determiner
- word order where appropriate
- capitalization
- common language-specific mistakes

Do not advertise a language whose fixture suite is clearly unusable.

---

# 29. FINE-TUNING — NOT A V1 BLOCKER

Do not block app delivery on training a new model.

Ship a working general multilingual model first.

However, create a clean future specialization path.

Add:

```text
ml/
├── README.md
├── eval/
├── data_schema/
└── training/
```

Document how Qwen3-0.6B could later be LoRA/QLoRA fine-tuned for minimal grammatical error correction.

Do not bundle training dependencies into the Android app.

Do not run model training during Flutter build.

---

# 30. TRAINING DATA LICENSE RULE

Future fine-tuning may only use datasets whose licensing permits the intended commercial model use.

Do not train on a dataset merely because it is public.

Record:

- dataset URL
- dataset license
- commercial-use status
- languages
- preprocessing

Reject non-commercial-only datasets for a commercial app model unless separately approved.

---

# 31. CORE EDITOR — HOME SCREEN

The home screen is the product.

Keep it extremely simple.

Recommended hierarchy:

```text
small header
↓
language: Auto
↓
large text editor
↓
Correct button
↓
result / suggestions
```

Do not use a dashboard.

Do not use cards for everything.

---

# 32. EDITOR PLACEHOLDER

Example:

> Paste or type something you'd like to correct…

Useful secondary action:

```text
Paste
```

Do not monitor clipboard in the background.

Clipboard is read only after explicit user action.

---

# 33. EDITOR ACTIONS

Primary:

**Correct**

After correction:

```text
Fix all
Copy
Share
Edit
```

Optional small action:

```text
Clear
```

Do not add 15 rewriting modes.

---

# 34. CORRECTION REVIEW MODE

Do not attempt to build a giant rich-text document editor.

Use two clear modes:

```text
Edit
Review
```

In Edit:

- standard performant text field

In Review:

- render correction spans clearly
- user can tap a highlighted correction
- suggestion sheet explains the change briefly
- apply one suggestion
- ignore one suggestion
- add spelling word to dictionary where supported
- Fix all

This keeps implementation reliable.

---

# 35. HARPER SUGGESTIONS

Map Harper lint data into a common domain model.

Example:

```text
CorrectionIssue
- id
- engine
- category
- start
- end
- original
- suggestions[]
- message
- severity
```

Do not expose raw Harper internals to UI.

---

# 36. MULTILINGUAL DIFF

The local model returns corrected text, not granular lints.

Use local text diff to derive edit operations.

Preferred:

`diff_match_patch`

or an equally maintained permissive local algorithm.

Create:

```text
CorrectionDiffService
```

It converts:

```text
original
+
corrected
```

into reviewable edits.

Do not call another model to explain differences.

---

# 37. MULTILINGUAL REVIEW

For model-based corrections, review UI should show concise changes such as:

```text
"sont" → "est"
```

or replaced phrase.

Do not invent detailed grammatical explanations if the model did not provide them reliably.

The product can simply label:

- Grammar
- Spelling
- Punctuation
- Change

where confidence is available.

Accuracy is more important than verbose explanation.

---

# 38. FIX ALL

`Fix all` must be deterministic.

For Harper:

apply non-conflicting accepted top suggestions in stable text-offset order.

Handle offset changes correctly.

For multilingual model:

the model output itself is the fixed-all version.

Never apply changes onto stale text without validating the revision ID.

---

# 39. TEXT REVISION SAFETY

Every correction run has:

```text
sourceHash
sourceRevision
```

If user edits the source after correction results were generated:

invalidate stale corrections.

Do not apply old offsets to new text.

---

# 40. COPY

Copy corrected text explicitly.

Show small confirmation:

**Copied**

Do not automatically overwrite clipboard before user requests it.

---

# 41. SHARE

Use Android share sheet.

Share plain corrected text.

No server.

No public share links.

---

# 42. ANDROID ACTION_PROCESS_TEXT — CORE DIFFERENTIATOR

Implement Android's system text-selection integration.

Register an Activity for:

```text
android.intent.action.PROCESS_TEXT
text/plain
```

The selection menu label should be short, for example:

**Fix grammar**

This feature must work from compatible apps such as text editors, browsers, messaging apps, email apps, etc.

Do not claim every third-party app supports writable PROCESS_TEXT.

---

# 43. PROCESS_TEXT INPUT

Read:

```text
Intent.EXTRA_PROCESS_TEXT
Intent.EXTRA_PROCESS_TEXT_READONLY
```

Do not read unrelated surrounding app content.

Only the selected text is processed.

---

# 44. PROCESS_TEXT WRITABLE FLOW

For writable source fields:

```text
select text in another app
↓
Fix grammar
↓
compact correction activity
↓
correct locally
↓
user confirms Apply
↓
return RESULT_OK
with EXTRA_PROCESS_TEXT = corrected text
↓
source app replaces selection
```

Do not make user copy/paste manually when Android supports returning replacement text.

---

# 45. PROCESS_TEXT READ-ONLY FLOW

If `EXTRA_PROCESS_TEXT_READONLY` is true:

show result with:

```text
Copy
Share
```

Do not pretend replacement is possible.

---

# 46. PROCESS_TEXT ACTIVITY UX

This should not open the full app home screen unnecessarily.

Use a compact dedicated route/activity.

Show:

```text
selected text preview
↓
correction state
↓
Apply / Copy / Cancel
```

If English:

Harper should return quickly.

If multilingual pack is required but not installed:

show:

**Offline language pack required**

with Download / Cancel.

Never cloud-fallback.

---

# 47. PROCESS_TEXT AND GUEST MODE

PROCESS_TEXT must work even if the user has never created an account.

No login redirect.

No paywall before correction.

All correction features work for guest users.

---

# 48. SHARE-TARGET INPUT

Also register the app for Android text sharing:

```text
ACTION_SEND
text/plain
```

Flow:

```text
Share
↓
GrammarFix
↓
text appears in editor
↓
Correct
```

Do not auto-correct before the user sees the incoming content unless that behavior is explicitly triggered by the share route and remains reversible.

---

# 49. NO CUSTOM KEYBOARD IN V1

Do not build an InputMethodService keyboard.

Do not ask the user to replace Gboard/Samsung Keyboard/SwiftKey.

The Android-wide feature is:

```text
ACTION_PROCESS_TEXT
```

This gives system-level selected-text correction without keyboard trust/permission complexity.

A custom keyboard can be researched later only if there is a strong user need.

---

# 50. APP NAVIGATION

Keep navigation tiny.

Recommended bottom destinations:

```text
Correct
Settings
```

Do not add History as a tab.

Do not add Profile.

Do not add Chat.

Use the V2 floating bottom-bar design if it remains visually clean with only two destinations.

If the design system is cleaner without a bottom bar for only two destinations, use a simple settings entry from the editor header — but preserve V2 navigation conventions where practical.

---

# 51. ICON RULE

Use the existing custom icon skills:

```text
skills/flutter_bold_icons/
skills/flutter_outline_icons/
```

Inspect both directories first.

Default controls:

```text
outline
```

Active/emphasized:

```text
bold
```

If a bottom bar exists:

all bottom-bar icons are bold, active and inactive.

Do not introduce random icon packages.

---

# 52. COLOR PALETTE — WHITE + GREEN

Completely remove old VidBrief palette identity.

Desired feel:

- clean
- private
- modern
- calm
- trustworthy
- writing-focused

Do not make it look like a crypto/finance app.

Do not use purple AI styling.

---

# 53. LIGHT PALETTE

Use this as the semantic starting point and tune for contrast:

```text
background
#F8FBF8

surface
#FFFFFF

surfaceSoft
#F0F7F2

surfaceStrong
#E5F1E8

primary
#178A4B

primaryPressed
#116B39

primarySoft
#DDF3E5

primaryStrong
#0D5A30

textPrimary
#17231B

textSecondary
#5A685F

textTertiary
#849087

border
#DCE6DF

borderStrong
#C5D4C9
```

---

# 54. DARK PALETTE

Create a proper green-tinted dark mode:

```text
backgroundDark
#0C1410

surfaceDark
#121D16

surfaceElevatedDark
#19271E

surfaceGreenDark
#163322

primaryDark
#66D58C

primaryPressedDark
#80E39F

primarySoftDark
#183B26

textPrimaryDark
#F2F8F3

textSecondaryDark
#C2CEC5

textTertiaryDark
#8EA096

borderDark
#27382D
```

Tune actual values based on accessibility testing.

---

# 55. COLOR RESTRAINT

White/neutral dominates.

Green is for:

- Correct CTA
- accepted fixes
- active selection
- progress
- privacy emphasis

Do not make every surface green.

Do not use gradients unless there is a compelling, restrained design reason.

---

# 56. CORRECTION COLORS

Do not use green for every lint highlight because green usually means accepted/correct.

Use subtle semantic distinction.

For example:

```text
Issue underline/background
→ soft amber or muted coral

Accepted/fixed
→ green

Ignored
→ neutral
```

Ensure color is not the only indicator.

Use underline/style/icon semantics too.

---

# 57. TYPOGRAPHY

Use a clean modern UI sans.

Writing text must be comfortable for paragraphs.

Prioritize:

- readability
- correct Arabic glyph shaping
- mixed-language rendering

Use Flutter/system font fallback appropriately.

Do not bundle a giant font library.

If a bundled family lacks Arabic glyphs, use a licensed Arabic fallback such as a suitable Noto Sans Arabic family only if needed and preserve its license.

---

# 58. RTL APP SUPPORT

App localization architecture must support RTL.

Arabic app locale:

- settings rows mirror logically
- text alignment uses start/end
- buttons remain logical
- back icons follow platform direction

Editor content direction is independent of app locale.

---

# 59. APP LOCALIZATION

At minimum architect and test app UI for:

```text
English
Arabic
French
```

Do not use runtime machine translation for interface strings.

Use ARB/localization files.

Never concatenate translated sentences.

---

# 60. NO WRITING HISTORY BY DEFAULT

Privacy-first default:

Do not save corrected text history automatically.

When app closes, editor text may remain only if the user explicitly enables local draft persistence.

Recommended default:

```text
Save editor draft locally = Off
```

If enabled:

store only app-private local data.

No sync.

---

# 61. SETTINGS

Keep Settings short.

Sections:

### Correction

```text
English variant
Default language: Auto
Custom dictionary
```

### Offline languages

```text
Multilingual pack
Download / Installed / Remove
```

### Privacy

```text
Save editor draft locally
Privacy policy
```

### Membership

```text
Go Ad-Free
Restore Purchases
```

only if monetization is enabled.

### Support

```text
Feedback
Rate App
```

### About

```text
Open source licenses
Version
Terms
```

No Account section.

---

# 62. MONETIZATION

Preserve RevenueCat + AdMob infrastructure from the template.

All correction features are available to guest/free users.

No feature is locked behind subscription.

RevenueCat entitlement:

```text
pro
```

means:

```text
remove ads
```

only.

If the business later chooses not to monetize this app, keep the monetization layer easy to disable without changing correction architecture.

---

# 63. PRO

Pro must never affect:

- Harper
- multilingual pack availability
- languages
- ACTION_PROCESS_TEXT
- custom dictionary
- Fix All
- copy/share

Pro only removes ads.

No AI credits exist.

---

# 64. ADS

Use conservative ad placement.

Never put an ad:

- inside PROCESS_TEXT activity
- while keyboard is open
- between user tapping Correct and receiving result
- in the language-pack download sheet
- on privacy/legal screens

Allowed free-user banner placement:

- editor bottom area only when keyboard is closed and enough vertical space exists
- Settings where appropriate

Collapse completely if unavailable.

---

# 65. INTERSTITIAL

If interstitial ads are retained:

use only after a natural manual workflow completion.

Initial rule:

```text
at least 8 successful full-app corrections
AND
minimum 15-minute cooldown
```

Possible trigger:

```text
user taps Copy after a successful full-app correction
↓
copy succeeds
↓
interstitial if eligible
```

Never delay the actual copy.

Never show interstitial for ACTION_PROCESS_TEXT.

No app-open ads.

---

# 66. NO ANALYTICS SDK

Do not add:

- Firebase Analytics
- Mixpanel
- Amplitude
- AppsFlyer
- Adjust
- Meta SDK

The product does not need them.

This also reduces risk of user-writing leakage.

---

# 67. ERROR HANDLING — HARPER

If Harper native engine fails to initialize:

show:

> English correction couldn't start. Please reopen the app.

Log only technical error codes.

Never log input text.

Do not silently send English to Qwen unless multilingual pack is installed and an explicit fallback has been tested.

English should remain Harper-first.

---

# 68. ERROR HANDLING — MULTILINGUAL MODEL

If model fails:

show:

> Offline language correction couldn't finish. Your text was not changed.

Actions:

```text
Retry
Edit
```

Never cloud fallback.

Never delete source text.

---

# 69. LOW-MEMORY DEVICES

The multilingual model will not be equally suitable for every Android device.

Before enabling it:

check practical device capability.

Use runtime/device benchmarks rather than arbitrary marketing claims.

If a device cannot load the model reliably:

show:

> This phone doesn't have enough available memory for the offline language pack. English correction still works.

Do not crash.

Do not download a large pack first and only then discover obvious incompatibility if capability can be checked earlier.

---

# 70. INFERENCE LIFECYCLE

Do not keep the large model resident forever.

Create a model session manager.

Rules:

- lazy-load when needed
- reuse for nearby corrections
- release after inactivity or memory pressure
- respond to Android lifecycle/memory callbacks

Do not reload 475 MB for every sentence.

---

# 71. INFERENCE CANCELLATION

If user edits text or leaves while multilingual inference is running:

cancel or ignore stale result.

Use source revision/hash.

Never overwrite newer text with an older model response.

---

# 72. INPUT LIMITS

The app is a text corrector, not a document processor.

Set a practical correction limit.

Suggested v1:

```text
Harper:
large paragraph / moderate text allowed

Multilingual model:
up to ~1,200–1,500 input tokens per correction chunk
```

For longer multilingual text:

split safely by paragraph/sentence boundaries, process sequentially, then reassemble preserving whitespace.

Do not split inside:

- URLs
- numbers
- short quotations
- emoji sequences where avoidable

---

# 73. CHUNKING

Create:

```text
CorrectionChunker
```

For multilingual text:

- preserve paragraph boundaries
- maintain exact separators/newlines
- process only chunks under context limit
- keep original formatting

Do not ask the user to manually split ordinary long text.

---

# 74. FORMATTING PRESERVATION

Correction must preserve:

- line breaks
- paragraph breaks
- bullets where plain text allows
- emojis
- URLs
- emails
- @handles
- hashtags
- numbers
- currency values

Do not "clean up" formatting unless it is clearly punctuation around prose.

---

# 75. CODE / TECHNICAL TEXT

If text contains a lot of code/syntax:

avoid aggressive grammar changes.

Harper already has parser concepts for prose/code contexts, but this mobile app primarily handles plain text.

For multilingual model:

if input is predominantly code or structured machine text, show:

> This looks like code or structured text. Grammar correction may not be useful.

Do not rewrite code identifiers.

---

# 76. SENSITIVE TEXT

The app may be used on sensitive messages.

No content moderation server is required because text never leaves the phone.

Do not censor normal user writing.

The app is a local text utility.

---

# 77. PROCESS_TEXT PRIVACY COPY

In onboarding, explain once:

> When you choose “Fix grammar” from Android's text-selection menu, only the text you selected is sent to this app, and correction happens on your phone.

Do not show this every time.

---

# 78. ONBOARDING

Maximum two concise screens.

Recommended screen 1:

**Private grammar correction**

> Your writing stays on your phone.

Screen 2:

**Works anywhere**

> Select text in supported Android apps and choose “Fix grammar.”

CTA:

**Start as guest**

Optional:

**See how**

Do not ask for permissions unnecessarily.

---

# 79. PROCESS_TEXT TUTORIAL

Provide an optional small tutorial in Settings/Home help:

```text
1. Select text in another app
2. Tap the three-dot text menu if needed
3. Choose Fix grammar
4. Apply the correction
```

Do not claim the action appears identically on every OEM/app.

---

# 80. NO ACCESSIBILITY SERVICE

Do not use Android AccessibilityService to read or replace text across apps.

Do not use screen scraping.

Do not monitor what user types globally.

ACTION_PROCESS_TEXT is sufficient and safer.

---

# 81. NO CLIPBOARD MONITORING

Do not monitor clipboard in background.

Only access clipboard after explicit user interaction such as:

**Paste**

Respect current Android clipboard/privacy behavior.

---

# 82. PERMISSIONS

Keep minimal.

Expected network-related permissions only for:

- AdMob/UMP
- RevenueCat
- Supabase feedback
- Google Play model delivery

No permission is needed for local correction itself.

Do not request:

- contacts
- camera
- microphone
- location
- SMS
- broad storage
- accessibility
- notification permission

unless a future explicit feature genuinely requires it.

---

# 83. MODEL PACK DOWNLOAD NETWORK

Model download is the only large network operation.

It contains no user text.

Offer a Wi-Fi suggestion for large download, but do not force Wi-Fi if Play APIs/user settings allow mobile data and user confirms.

Never start an unmetered background download without user awareness.

---

# 84. PRIVACY POLICY

Generate:

```text
docs/legal/privacy.md
```

Accurately state:

- no sign-in required
- corrections run locally
- English uses local Harper
- multilingual correction uses an optional local on-device model
- user writing is not sent to Mogate or an AI API
- model weights may be downloaded from Google Play
- optional anonymous feedback may be sent to Supabase
- AdMob/UMP and RevenueCat processing if enabled
- custom dictionary stays local
- optional local draft behavior

Do not claim "no data collected" if ads/feedback/purchases process their own data.

---

# 85. TERMS

Generate:

```text
docs/legal/terms.md
```

State:

- correction suggestions may be imperfect
- user is responsible for final text
- no guarantee of semantic correctness
- multilingual model may behave differently across languages/devices
- no professional/legal advice is provided

Do not overcomplicate.

---

# 86. DELETE ACCOUNT

No account is required and no Mogate account is created in normal use.

Generate the generic website document if the template requires it:

```text
docs/legal/delete-account.md
```

but clearly state that the app does not require an account and therefore normal guest users have no account to delete.

If optional account functionality is absent, do not show a fake Delete Account control in the app.

---

# 87. LOCAL DATA DELETE

Settings should include:

**Clear local data**

It may clear:

- optional saved draft
- custom dictionary
- preferences

Do not remove the multilingual pack unless user explicitly chooses to remove it, unless the confirmation clearly says it will.

---

# 88. OPEN-SOURCE LICENSES

Create third-party notices for:

- Harper
- Qwen3 model
- LiteRT-LM/runtime
- diff-match-patch if used
- fonts if bundled
- any native build helper requiring notice

Create:

```text
THIRD_PARTY_NOTICES.md
docs/licenses/harper.md
docs/licenses/qwen3.md
```

Record exact versions/commits.

---

# 89. MODEL LICENSE

Verify the exact shipped Qwen artifact retains the appropriate permissive license and model notice.

Do not assume a community-converted artifact has the same provenance without checking.

Document:

- upstream model
- converter/source
- quantization
- checksum
- license

---

# 90. DESIGN — HALLMARK AUDIT

Use:

- `flutter-design-polish`
- `flutter-ux-quality`
- `flutter-hallmark`

Reject:

- generic AI sparkle UI
- purple gradients
- giant hero areas
- excessive rounded cards
- 12 feature chips
- writing analytics dashboard
- fake productivity scores
- streak gamification

The app is a utility.

It should feel calm and immediate.

---

# 91. HOME RESPONSIVENESS

Small phones:

- editor remains usable with keyboard
- Correct button remains reachable
- review list does not hide behind keyboard

Large phones/tablets:

- center content with sensible max width
- do not stretch paragraphs across entire tablet

---

# 92. KEYBOARD BEHAVIOR

The app works with the user's normal keyboard.

Do not replace it.

When the keyboard opens:

- hide banner ads
- keep Correct accessible
- avoid layout jump
- respect system insets

---

# 93. PERFORMANCE TARGET — ENGLISH

English correction should feel instant for ordinary messages/paragraphs.

Benchmark:

```text
100 chars
500 chars
2,000 chars
5,000 chars
```

Run Harper off the main UI thread/isolate/FFI path as needed.

No frame jank.

---

# 94. PERFORMANCE TARGET — MULTILINGUAL

Measure on real mid-range Android hardware.

Record:

- model load time
- first-token latency
- total correction latency
- peak memory
- model resident memory

Do not promise "instant" if device cannot achieve it.

Use progress state:

**Correcting on your device…**

No fake AI typing animation.

---

# 95. MODEL WARMUP

After multilingual model is installed:

optionally perform a tiny local warmup only when it will not hurt startup/battery.

Do not load model on every app launch.

First English-only launch must remain fast.

---

# 96. BATTERY / THERMALS

The multilingual model should run only on explicit correction actions.

No continuous background inference.

No real-time per-keystroke LLM correction.

This is crucial for battery and heat.

Harper may support near-real-time checks inside the app, but v1 should still prioritize on-demand correction simplicity.

---

# 97. REAL-TIME ENGLISH CHECKING

Optional inside the editor only:

If Harper performance remains excellent and UX is clean, run debounced English lint after typing pauses.

Do not enable this for the multilingual LLM.

If implementing:

- debounce
- cancel stale runs
- no network
- no visible spinner

Primary **Correct** button must still work.

---

# 98. NO STYLE REWRITE MODES

Do not add:

```text
Formal
Friendly
Shorter
Longer
Professional
Academic
Casual
```

in v1.

These increase model scope and reduce predictability.

This app corrects text.

It does not rewrite the user's personality.

---

# 99. CORRECTION CATEGORIES

Keep visible categories simple:

```text
Grammar
Spelling
Punctuation
Clarity
```

Only show category if engine can support it reliably.

Do not fabricate certainty.

---

# 100. ACCESSIBILITY

Require:

- TalkBack labels
- large touch targets
- text scaling
- non-color-only issue indication
- RTL support
- keyboard navigation where practical
- sufficient contrast

Review correction highlights with color-blind-friendly semantics.

---

# 101. TEST — HARPER

Create English regression fixtures covering:

- subject/verb agreement
- articles
- punctuation
- capitalization
- spelling
- common confusions
- dialect differences
- names in user dictionary

Test actual native bridge, not only mocked Dart output.

---

# 102. TEST — NATIVE RUST BRIDGE

Tests must cover:

- initialization
- UTF-8 input
- empty text
- long text
- emoji
- apostrophes
- newline preservation
- lint serialization
- malformed native response handling

Add Android integration test for real library load.

---

# 103. TEST — MULTILINGUAL

For each supported language:

- grammar error
- spelling error where model can handle it
- punctuation
- already-correct sentence
- names
- numbers
- URL/email preservation
- mixed-language input

Arabic additionally:

- gender agreement
- number agreement where fixtures are reliable
- Arabic punctuation
- Arabic/Latin mixed content
- RTL display

Do not write tests that assume only one valid natural-language correction when multiple are acceptable.

---

# 104. TEST — NO TRANSLATION

Critical.

For every non-English language:

input must remain in same language.

Create explicit tests that fail if the model translates to English.

---

# 105. TEST — SEMANTIC PRESERVATION

Create fixtures with:

- names
- addresses
- money
- dates
- product names
- negation

The model should not casually change meaning.

When output violates guardrails, fallback to original.

---

# 106. TEST — PROCESS_TEXT

Android instrumentation tests:

- writable PROCESS_TEXT input
- read-only PROCESS_TEXT input
- empty/missing extra
- English correction
- multilingual pack installed
- multilingual pack missing
- cancel
- apply result
- result returned to caller

Verify correct Intent result contract.

---

# 107. TEST — SHARE TARGET

Test:

```text
ACTION_SEND text/plain
```

with:

- short text
- long text
- Arabic
- empty share

Incoming text appears correctly and is not auto-uploaded anywhere.

---

# 108. TEST — MODEL DOWNLOAD

Use Play delivery test tools/tracks.

Test:

- fresh install
- start download
- background app
- kill/reopen
- resume
- failure
- retry
- complete
- model path access
- update pack
- remove pack
- insufficient storage

Do not mark model feature done using only a locally copied file.

---

# 109. TEST — OFFLINE

After multilingual pack installation:

turn on airplane mode.

Verify:

- English correction
- Arabic correction
- French correction
- Spanish correction
- German correction
- Portuguese correction
- Italian correction
- PROCESS_TEXT
- Share target
- custom dictionary

all work.

Ads/feedback/purchases may be unavailable, but correction must work.

---

# 110. NETWORK PRIVACY TEST

Run traffic inspection while correcting representative sensitive text.

Confirm no request body, query string, event, header, log or crash report contains user writing.

Test while:

- AdMob enabled
- RevenueCat enabled
- Supabase feedback infrastructure initialized

Correction text must never be transmitted.

---

# 111. TEST — STALE RESULTS

Start correction.

Edit source before result returns.

Verify old result is not applied.

Test both:

- Harper
- Qwen

---

# 112. TEST — MEMORY PRESSURE

On a representative lower-memory device/emulator:

- load multilingual model
- correct several texts
- background app
- resume
- trigger Android memory pressure where possible

App must not corrupt text or crash repeatedly.

---

# 113. TEST — DARK / RTL

Audit:

```text
English light
English dark
Arabic light
Arabic dark
```

Screens:

- onboarding
- editor
- review
- suggestion sheet
- language download
- Settings
- custom dictionary
- PROCESS_TEXT activity
- paywall if enabled

---

# 114. STORE POSITIONING

Create:

```text
docs/store/google-play-listing.md
```

Position around:

- private grammar checker
- offline English grammar
- multilingual offline correction
- spelling and punctuation
- Android selected-text correction
- no account required

Do not make unsubstantiated claims such as:

- "more accurate than Grammarly"
- "best grammar checker"
- "100% accurate"

Do not use competitor trademarks as the product title.

---

# 115. SCREENSHOT PLAN

Recommended screenshots:

1. Paste or type → Correct
2. Review highlighted fixes
3. Fix grammar from Android text selection
4. Offline multilingual language pack
5. Arabic/RTL correction
6. Privacy: writing stays on device

Use real app UI.

---

# 116. DATA SAFETY

Create:

```text
docs/store/data-safety.md
```

Base it on actual runtime SDKs.

Clearly separate:

- writing content: local, not collected
- optional feedback: user submitted
- ads/UMP processing
- RevenueCat purchase processing

Do not guess current AdMob/RevenueCat declarations.

Verify release SDK documentation.

---

# 117. GOOGLE PLAY AI/MODEL DELIVERY

Document exactly how the model pack is delivered.

Create:

```text
docs/setup/offline-model-delivery.md
```

Include:

- delivery mechanism
- module/pack name
- model filename
- size
- checksum
- install state API
- debug/local testing
- internal track testing
- update process
- removal behavior

No Mogate model server.

---

# 118. SETUP DOCUMENT

Create:

```text
docs/setup/grammar-fix-setup.md
```

Include:

- template bootstrap
- app identity
- Rust toolchain
- cargo/NDK integration
- Harper revision
- Qwen model revision
- LiteRT-LM integration
- Play model/asset delivery
- Supabase feedback schema
- RevenueCat
- AdMob/UMP
- legal URLs
- release signing
- Play setup
- 16 KB verification

---

# 119. README

README must describe architecture simply:

```text
English
→ Harper on-device

Arabic/French/Spanish/German/Portuguese/Italian
→ optional Qwen3-0.6B on-device pack

Android-wide selected text
→ ACTION_PROCESS_TEXT
```

State clearly:

**User writing is not sent to a grammar server.**

---

# 120. UNIT ECONOMICS

Create:

```text
docs/business/unit-economics.md
```

Correction compute cost per user:

```text
$0 server AI cost
```

Model distribution is via Google Play, not a paid inference API.

Variable external cost comes only from normal services such as ads/subscriptions/Supabase feedback if used.

There are no LLM token costs.

---

# 121. NO GEMINI

Absolute for v1.

Do not add Gemini as:

- fallback
- rewrite mode
- multilingual fallback
- explanation generator
- language detector

If local model cannot perform a correction, preserve original text.

Cloud AI may only be reconsidered in a future explicit product decision.

---

# 122. MODEL QUALITY DOCUMENT

Create:

```text
docs/ml/model-evaluation.md
```

Record:

- device tested
- model artifact
- language
- fixture pass rate
- representative failures
- average latency
- peak memory

Be honest.

Do not claim multilingual parity with Harper if not measured.

---

# 123. MODEL UPDATE STRATEGY

The model pack should be independently updatable through a new app release/Play pack version.

Keep:

```text
modelVersion
modelHash
runtimeCompatibilityVersion
```

in local metadata.

If model/runtime mismatch:

avoid loading and show update guidance.

---

# 124. APP UPDATE SAFETY

Updating the app must not delete:

- custom dictionary
- preferences
- optional local draft
- language-pack installed state where Play supports retention

Use versioned local migrations.

---

# 125. RELEASE BUILD

Run:

```text
flutter pub get
flutter analyze
flutter test
```

Build:

```text
flutter build appbundle --release
```

Run Android/native integration tests.

Run model pack delivery tests.

Run the repository 16 KB checker.

Do not release from debug assumptions.

---

# 126. CURRENT PLAY REQUIREMENTS

Before release, verify current:

- target SDK
- compile SDK
- AGP
- Gradle/JDK
- Android App Bundle size limits
- model/asset delivery rules
- 16 KB page-size requirements
- Data Safety
- Ads declaration
- privacy policy
- app access
- current Play Policy Insights

Do not rely on stale policy memory.

---

# 127. ADS POLICY

If app contains AdMob:

Play Console:

```text
Contains ads = Yes
```

Do not make ads interfere with core selected-text correction.

No deceptive ad placement near Apply/Copy buttons.

---

# 128. APP ACCESS

No account is required.

Play reviewer can access correction immediately.

No test credentials should be necessary.

---

# 129. LEGAL URLS

Use:

```text
https://grammar-fix.mogate.tech/privacy
https://grammar-fix.mogate.tech/terms
https://grammar-fix.mogate.tech/delete-account
```

The delete-account page may explain that the current app does not require an account.

---

# 130. DEFINITION OF DONE

The app is complete only when:

- user can start as guest
- no sign-in is required
- all correction features work for guest
- English correction works locally with Harper
- English works offline immediately after app install
- custom dictionary works locally
- Android ACTION_PROCESS_TEXT works
- writable selected text can be returned to source app
- read-only PROCESS_TEXT is handled correctly
- ACTION_SEND text sharing works
- multilingual model pack downloads on demand from Google Play
- model pack is not part of normal base install
- Arabic works locally after pack download
- French works locally after pack download
- Spanish works locally after pack download
- German works locally after pack download
- Portuguese works locally after pack download
- Italian works locally after pack download
- multilingual model runs through local LiteRT-LM
- no Gemini/API correction exists
- no user writing leaves device
- no cloud fallback exists
- RTL is correct
- result diff/review works
- Fix All works
- copy/share works
- stale results cannot overwrite new text
- white/green palette is complete
- dark mode is polished
- custom icons follow project rules
- Supabase never receives correction text
- Pro, if enabled, only removes ads
- ads never interrupt PROCESS_TEXT
- offline tests pass
- network privacy test passes
- native libraries pass 16 KB checks
- current Google Play requirements are verified

---

# 131. FINAL REPORT

When implementation is finished, provide:

## Product

List actual user-facing features.

## English engine

Report:

- Harper version/commit
- Rust bridge design
- measured correction latency
- supported English variants

## Multilingual

Report:

- model exact name/version
- quantization
- actual download size
- Play delivery mechanism
- supported advertised languages
- per-language fixture results
- model load latency
- correction latency
- peak memory on tested devices

## Android integration

Report:

- ACTION_PROCESS_TEXT
- read-only/writable behavior
- ACTION_SEND
- device/app compatibility notes

## Privacy

Confirm:

```text
user writing never leaves the device
```

List every networked SDK and confirm no writing text is passed to it.

## Guest

Confirm all features work without sign-in.

## Supabase

State exactly what Supabase is used for.

Confirm no correction/history/custom-dictionary data is stored there.

## Monetization

If enabled, confirm:

```text
pro = remove ads only
```

## Design

List final semantic green/white light/dark tokens.

## Tests

Report:

```text
flutter analyze
flutter test
Harper native integration tests
multilingual fixtures
Arabic RTL tests
PROCESS_TEXT instrumentation tests
ACTION_SEND tests
model download tests
offline tests
network privacy test
low-memory test
release AAB
16 KB check
Play Policy Insights
```

## Blockers

Only genuine unresolved blockers.

---

# 132. FINAL PRODUCT PRINCIPLE

The product should be explainable in one sentence:

> Correct your writing privately, anywhere on Android.

Architecture:

```text
English text
→ Harper
→ instant local corrections

Non-English text
→ optional downloaded local model
→ local correction

Selected text in another app
→ Android PROCESS_TEXT
→ same local engines
→ return correction
```

No account required.

No cloud AI.

No writing upload.

No custom keyboard.

No unnecessary writing-suite features.

The app wins by being:

```text
simple
fast
private
multilingual
offline
useful everywhere
```
