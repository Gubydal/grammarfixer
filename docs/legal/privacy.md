# Privacy Policy — GrammarFix

**Effective Date**: January 1, 2026  
**Publisher**: Mogate (`mogatebusiness@gmail.com`)  
**Application ID**: `com.mogate.grammarfix`  
**Website**: `https://grammar-fix.mogate.tech`

---

## 1. Summary: Absolute Local-First Privacy

GrammarFix is built around a single foundational promise: **your writing belongs solely to you and never leaves your device.**

- **100% Local Grammar & Spell Correction**: All grammar, typo, punctuation, and style checks are performed locally in-process on your Android device via `harper-core` FFI and local on-device neural models.
- **Zero Writing Telemetry**: Your input text, selected text, keyboard keystrokes, personal style profile, custom dictionary words, and clipboard interactions are **NEVER transmitted, logged, or stored on remote servers**.
- **Guest-First**: Direct editor access with no sign-in or account gate required.
- **No AccessibilityService**: GrammarFix does not use AccessibilityService to scrape or observe screen contents.

---

## 2. Information Handled Locally On-Device

The following data is processed and stored **exclusively in private local storage on your device**:

1. **In-App Editor**: Any text you type or paste into the GrammarFix editor is checked in local RAM. Drafts are discarded on close unless you explicitly enable "Save Editor Draft Locally" in Settings (Default: Off).
2. **Selected Text Action (`ACTION_PROCESS_TEXT`)**: When you select text in any app and choose "Fix grammar", the selected text is received into a lightweight local dialog, corrected on-device, and returned directly to the calling app.
3. **System Spell Checker (`SpellCheckerService`)**: When enabled in Android Text Services, spell and grammar suggestions are computed entirely on-device without remote queries.
4. **Optional Grammar Keyboard (`InputMethodService`)**:
   - The GrammarFix keyboard processes typed words locally in an ephemeral buffer to offer real-time spelling and grammar suggestions.
   - **Sensitive Field Protection**: Password fields, PIN inputs, OTPs, and credit card number variations automatically disable all correction suggestions and style learning.
   - Keystrokes are never transmitted to Mogate, Google, or any third party.
5. **Personal Writing Style Profile**:
   - Learns writing preferences (such as dialect conventions, contraction habits, and preferred vocabulary) on-device from your accept/reject actions.
   - Full user sentences or messages are **never retained** for style learning.
   - **Private Mode**: When Private Mode is toggled ON, personal style learning is paused and all ephemeral context is cleared.
   - Users can reset their style profile at any time via Settings -> Personal Style -> "Reset Style".
6. **Custom Dictionary**: Whitelisted words are stored in local `SharedPreferences` and never synchronized to the cloud.
7. **Optional Multilingual Model Pack**: When you download the optional ~475 MB multilingual pack, weights are downloaded to local private storage and all subsequent multilingual inference (Arabic, French, Spanish, German, Portuguese, Italian, English) executes 100% offline.

---

## 3. Information We Do NOT Collect

We do NOT collect, transmit, store, or sell:
- Any text you paste, type, select, or correct.
- Any words in your personal dictionary or style profile.
- Keystrokes or keyboard telemetry.
- Contact lists, location data, or personal identity data.

---

## 4. Optional In-App Purchases & Advertising

- **Pro Membership**: Managed securely via Google Play Billing and RevenueCat. When you purchase Pro, anonymized receipt verification tokens are processed to unlock ad-free features.
- **AdMob (Free Tier Only)**: Displays standard banner and interstitial ads on the free tier. Ad SDKs receive zero text, writing context, or keyboard data. Pro membership removes all ads completely.

---

## 5. Contact Us & Data Deletion

Because user writing and style profiles are stored exclusively on your device, clearing app data in Android Settings or uninstalling the app permanently removes all local data.

For privacy inquiries, contact the **Mogate Privacy Team**: `mogatebusiness@gmail.com`
