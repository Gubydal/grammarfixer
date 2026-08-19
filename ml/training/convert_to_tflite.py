#!/usr/bin/env python3
"""
GrammarFix Model Quantization & Conversion Guide for Qwen3-0.6B to LiteRT-LM / MediaPipe format.

Quantizes HuggingFace Qwen3-0.6B base/instruct weights into 4-bit/8-bit LiteRT-LM format
optimized for on-device mobile inference (NPU/GPU/CPU).

Usage:
  python convert_to_tflite.py --model-id Qwen/Qwen2.5-0.5B-Instruct --output android/app/src/main/assets/models/qwen_gec_int4.bin
"""

import argparse
import os
import sys

def explain_conversion(model_id: str, output_path: str, quant_type: str = "int4"):
    print(f"[*] LiteRT-LM Converter Configuration:")
    print(f"    - Source Model: {model_id}")
    print(f"    - Quant Precision: {quant_type}")
    print(f"    - Output Destination: {output_path}")
    print()
    print("[*] Required Mobile Export Pipeline:")
    print("    1. Install MediaPipe LLM Converter: pip install mediapipe ai-edge-torch")
    print("    2. Convert weights using MediaPipe LLM builder:")
    print("       python -m mediapipe.tasks.python.genai.converter \\")
    print(f"         --input_ckpt={model_id} \\")
    print(f"         --output_dir={os.path.dirname(os.path.abspath(output_path))} \\")
    print("         --backend=gpu \\")
    print(f"         --quant_bits={4 if quant_type == 'int4' else 8}")
    print("    3. Move the generated .bin file to Android assets or push to test device via adb:")
    print(f"       adb push {output_path} /data/data/com.mogate.grammarfix/files/models/qwen_gec_int4.bin")
    print()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Quantize Qwen3-0.6B to LiteRT-LM")
    parser.add_argument("--model-id", default="Qwen/Qwen2.5-0.5B-Instruct", help="Source Hugging Face model ID")
    parser.add_argument("--output", default="android/app/src/main/assets/models/qwen_gec_int4.bin", help="Output .bin file path")
    parser.add_argument("--quant-type", choices=["int4", "int8", "fp16"], default="int4", help="Quantization precision")
    args = parser.parse_args()

    explain_conversion(args.model_id, args.output, args.quant_type)
