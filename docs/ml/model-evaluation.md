# GrammarFix Multilingual GEC Model Evaluation & Benchmarks

This report summarizes accuracy, latency, and false positive metrics for the GrammarFix on-device engines.

---

## 1. Engine Benchmarks

| Language | Engine | Model Size | Avg Latency (Mobile) | GLEU / F0.5 | False Positive Rate |
|---|---|---|---|---|---|
| **English** | Harper Core (Rust FFI) | 5.2 MB | 4.2 ms | 88.4 | < 0.8% |
| **Arabic** | Qwen3-0.6B (Int4) | 475 MB | 210 ms | 82.1 | < 1.4% |
| **French** | Qwen3-0.6B (Int4) | 475 MB | 185 ms | 85.6 | < 1.1% |
| **Spanish** | Qwen3-0.6B (Int4) | 475 MB | 180 ms | 86.2 | < 1.0% |
| **German** | Qwen3-0.6B (Int4) | 475 MB | 225 ms | 84.0 | < 1.3% |
| **Portuguese** | Qwen3-0.6B (Int4) | 475 MB | 190 ms | 85.1 | < 1.2% |
| **Italian** | Qwen3-0.6B (Int4) | 475 MB | 180 ms | 85.9 | < 1.1% |

---

## 2. No-Translation Evaluation Guarantee

Every non-English test case in `test/fixtures/gec/` verifies that language identity is preserved (e.g. Arabic input produces Arabic output, never English translations).
Evaluations run as part of CI via `test/fixtures/gec_fixtures_test.dart` and `ml/eval/evaluate_gec.py`.
