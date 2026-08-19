# On-Device SLM Fine-Tuning & Quantization Plan

## 1. Objective

Produce an ultra-compact 0.5B-0.6B parameter Grammatical Error Correction (GEC) model specifically fine-tuned for on-device mobile execution with LiteRT-LM (TFLite / MediaPipe).

---

## 2. Dataset Strategy

1. **Synthetic Noise Injection**:
   - Keyboard typo simulation (adjacent QWERTY and Arabic layout transpositions).
   - Character repetition (`helloooo` -> `hello`) and missing letter injections.
   - Word boundary corruptions (`alot`, `inthe`, `some thing`).
2. **Corpora**:
   - English: BEA-2019, CoNLL-2014, Write & Improve / LOCNESS.
   - Arabic: QALB-2014 / 2015 Shared Task datasets.
   - French / Spanish / German: Lang-8 & WMT monolingual error injection corpora.
3. **Protected Span Conditioning**:
   - Pre-training examples containing code blocks, URLs, emails, and hashtags with explicit loss masking on protected segments.

---

## 3. Quantization & Export Pipeline

1. **Base Architecture**: Qwen2.5-0.5B-Instruct / Gemma-2B-IT.
2. **LoRA Fine-Tuning**: Rank 16, Alpha 32 on attention and MLP projections.
3. **Quantization**: INT4 / INT8 weight-only quantization using `tflite_support` / MediaPipe GenAI converter.
4. **Target Size**: 350 MB - 475 MB final bundled package.
