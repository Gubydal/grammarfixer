import '../entities/correction_result.dart';
import '../entities/language.dart';

/// Abstract contract for local on-device small language model (SLM) inference.
///
/// Enables seamless swapping of underlying model runtimes (LiteRT-LM, MediaPipe LLM Inference,
/// ONNX Runtime, llama.cpp) without modifying repositories or presentation cubits.
abstract class LocalGrammarModel {
  /// Returns whether the model weights are loaded and ready in device memory.
  Future<bool> isReady();

  /// Runs grammatical error correction and style refinement on [text] in [language].
  Future<CorrectionResult> correct({
    required String text,
    required AppLanguage language,
    int revision = 0,
  });
}
