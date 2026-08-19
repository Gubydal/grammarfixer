# Multi-Layer Grammar & Typo Correction Pipeline

## 1. System Architecture Overview

GrammarFix employs a multi-tiered on-device correction pipeline designed to deliver instantaneous, accurate, context-aware writing enhancements while preserving user intent, formatting, and domain tokens.

```mermaid
flowchart TD
    In[User Text Input] --> PSD[ProtectedSpanDetector]
    PSD -->|Extracts Spans & Protected Ranges| Pipeline
    
    subgraph Pipeline [Multi-Engine Candidate Generation]
        TCE[TypoCandidateEngine\n- Edit distance\n- Joined / Split words\n- Repeated letter collapse]
        HE[HarperEngine\n- harper-core Rust FFI\n- Subject-Verb Agreement\n- Tense & Homophones\n- Dialect (US/UK/AU/CA)]
        MLE[MultilingualEngine\n- LiteRT-LM Qwen3-0.6B\n- 3-sentence sliding window\n- Multilingual GEC]
    end
    
    TCE --> CM[CorrectionMerger]
    HE --> CM
    MLE --> CM
    
    subgraph Personalization [On-Device Adaptation]
        WSP[(WritingStyleProfile\n- SharedPreferences\n- Dialect\n- Accepted/Rejected Styles)]
    end
    
    WSP --> CM
    CM --> Output[Unified Non-Conflicting Corrections]
```

---

## 2. Core Components

### 2.1 `ProtectedSpanDetector`
Scans raw text using static regular expressions to find non-text tokens that must never be modified by grammar or typo engines:
- URLs (`https://...`, `www....`)
- Email addresses (`user@domain.com`)
- Usernames (`@handle`) and Hashtags (`#Tag`)
- Inline code (`foo()`) and multi-line fenced code blocks (```` ```...``` ````)
- File paths (`/var/log/`, `C:\Code\`) and Semantic Versions (`v1.2.3`)
- Currency expressions (`$99.99`, `€45`) and SKU numbers
- HTML tags (`<div>`, `<span class="...">`)

Any engine suggestion whose start or end bounds intersect a protected span is rejected by `isEditAllowed()`.

### 2.2 `TypoCandidateEngine`
Provides fast (sub-5ms) candidate detection for character-level and word-boundary mistakes:
- **Joined words**: `alot` -> `a lot`, `inthe` -> `in the`, `aswell` -> `as well`
- **Split words**: `some thing` -> `something`, `every day` -> `everyday`
- **Repeated characters**: Collapses 3+ identical letters (`hellooooo` -> `hello`, `whattt` -> `what`), while strictly preserving valid English double-letter words (`coffee`, `bookkeeper`, `committee`, `balloon`, `success`).
- **Transpositions & missing letters**: `recieved` -> `received`, `teh` -> `the`, `thsi` -> `this`, `becuase` -> `because`.
- **Missing apostrophes**: `cant` -> `can't`, `dont` -> `don't`, `theyre` -> `they're`.

### 2.3 `HarperEngine` (Rust `harper-core` FFI)
High-performance deterministic rule engine for English syntax and punctuation:
- **Agreement**: `The dogs is` -> `The dogs are`, `She don't` -> `She doesn't`, `I has` -> `I have`.
- **Tense**: `I have went` -> `I have gone`, `She will came` -> `She will come`, `He had saw` -> `He had seen`.
- **Articles & Homophones**: `He is engineer` -> `He is an engineer`, `Their going` -> `They're going`, `better then` -> `better than`.
- **Dialects**: Adapts spelling conventions for US (`color`, `organize`), UK (`colour`, `organise`), AU, and CA.

### 2.4 `MultilingualEngine` (LiteRT-LM)
Runs quantized Qwen3-0.6B LLM locally via Google LiteRT-LM / MediaPipe LLM Inference:
- Supports Arabic, French, Spanish, German, Portuguese, and Italian.
- Applies strict no-translation and prompt-injection guardrails.
- Uses sliding 3-sentence windows (previous + target + next) for contextual coherence.

### 2.5 `CorrectionMerger`
Combines candidate streams, resolves overlapping edits by prioritizing higher confidence and deterministic token boundaries, and applies the user's `WritingStyleProfile`. Objective grammatical correctness rules are never suppressed.
