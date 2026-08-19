# GrammarFix ML & GEC Inference Pipeline

This directory contains the tools, schemas, and quantization pipeline for GrammarFix's on-device multilingual grammar correction models (Qwen3-0.6B).

## Architecture

- **English**: `harper-core` via Rust C-ABI (`native/harper_bridge/`) compiled for ARM64/x86_64 with 16 KB memory page-size alignment.
- **Multilingual (ar, fr, es, de, pt, it)**: Qwen3-0.6B quantized via LiteRT-LM / MediaPipe LLM Inference to 4-bit/8-bit weights (~475 MB), packaged and delivered on-demand via Google Play Feature Delivery / Asset Delivery.

## Directory Structure

```
ml/
├── data_schema/
│   └── schema.json         # Standardized GEC token schema & fixture contract
├── eval/
│   └── evaluate_gec.py     # Evaluation runner for precision, recall, and GLEU / F0.5
├── training/
│   └── convert_to_tflite.py # Quantization & LiteRT-LM packaging script
└── README.md
```

## Running Evaluation

```bash
python ml/eval/evaluate_gec.py --fixtures test/fixtures/gec/ --lang all
```
