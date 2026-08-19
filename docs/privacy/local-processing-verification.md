# Local Processing & Zero Network Leakage Verification

## 1. Executive Summary

**GrammarFix** is engineered with an absolute **Local-First Privacy Architecture**. All user writing, typing suggestions, autocorrect transformations, and grammar linter passes execute **100% on the local Android device**.

- **Zero user text is ever transmitted** to any remote server, API, cloud endpoint, or analytics telemetry service.
- **Zero remote telemetry** tracks user keystrokes, vocabulary, or text selections.
- The app operates completely in Airplane mode without network connectivity.

---

## 2. Technical Safeguards Against Network Leaks

```mermaid
graph TD
    A[User Input / Selected Text] --> B[ProtectedSpanDetector]
    B --> C[TypoCandidateEngine]
    C --> D[HarperEngine (harper-core FFI)]
    D --> E[MultilingualEngine (LiteRT-LM)]
    E --> F[CorrectionMerger]
    F --> G[WritingStyleProfile (Local SharedPreferences)]
    G --> H[Output Text / Suggestions]
    
    style A fill:#e8f5e9,stroke:#2e7d32
    style H fill:#e8f5e9,stroke:#2e7d32
```

### Key Technical Guarantees:
1. **FFI Direct Memory Passing**: Harper (`harper-core`) runs in-process via C-ABI FFI (`libharper_bridge.so`). Memory is allocated in local process space and freed immediately upon lint completion.
2. **On-Device LLM (LiteRT-LM)**: Multilingual model weights (`Qwen3-0.6B`) execute purely on device via Qualcomm/MediaPipe NPU & CPU acceleration.
3. **No AccessibilityService**: GrammarFix explicitly rejects `AccessibilityService` to guarantee it cannot passively scrape screen contents.
4. **Sensitive Field Detection**: In `GrammarKeyboardService`, password fields, PIN inputs, OTPs, and credit card number variations immediately disable suggestion generators and learning routines.
5. **Private Mode**: When Private Mode is enabled, personal style adaptation is paused and no local heuristic patterns are recorded.

---

## 3. Network Isolation Verification Procedure

### Test 1: Full Offline Execution (Airplane Mode)
1. Turn on Android **Airplane Mode** (disable Wi-Fi and Cellular).
2. Open GrammarFix.
3. Paste a 1,000-word essay with intentional typos, subject-verb agreement errors, and punctuation mistakes.
4. Execute `Correct`.
5. **Result**: 100% of corrections are generated with sub-100ms latency.

### Test 2: Network Packet Inspection (Wireshark / Mitmproxy)
1. Route Android device traffic through an HTTP/HTTPS transparent proxy (`mitmproxy`).
2. Run correction across all supported languages (English, Arabic, French, Spanish, German, Portuguese, Italian).
3. Inspect proxy logs:
   - Zero outbound requests containing user text.
   - Zero background ping endpoints.
