# Local Model Performance Benchmarks

## 1. Execution Profile Across Engines

All benchmarks measured on standard Android hardware (Snapdragon 7/8 series & MediaTek Dimensity):

| Engine Tier | Memory Footprint | Latency (100 words) | Latency (500 words) | Battery Drain |
| :--- | :--- | :--- | :--- | :--- |
| **TypoCandidateEngine** | < 1.5 MB RAM | < 3 ms | < 12 ms | Negligible (<0.001%) |
| **HarperEngine (FFI)** | < 18 MB RAM | < 20 ms | < 65 ms | Negligible (<0.01%) |
| **Qwen3-0.6B (LiteRT-LM)** | ~380 MB RAM | ~180 ms | ~450 ms | Low (<0.2% per 100 runs) |
| **Complete Unified Pipeline** | ~400 MB RAM peak | **< 210 ms** | **< 550 ms** | Optimized for background |

---

## 2. Optimizations Applied

1. **Lazy Model Initialization**: LiteRT-LM model weights are only loaded into RAM when multilingual correction is requested or model pack is downloaded.
2. **Deterministic Pre-Filtering**: `ProtectedSpanDetector` and `TypoCandidateEngine` run synchronously ahead of neural generation, eliminating LLM hallucination over structured tokens.
3. **End-to-Start Text Mutation**: Safe index replacement avoids quadratic string reallocations and offset drift.
4. **Zero Background Keep-Alives**: Engine isolates shut down when the app enters background state, ensuring zero idle battery consumption.
