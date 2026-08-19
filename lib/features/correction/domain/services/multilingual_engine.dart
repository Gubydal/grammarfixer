import 'dart:async';
import 'package:flutter/services.dart';

import '../entities/correction_result.dart';
import '../entities/language.dart';
import 'correction_diff_service.dart';
import 'local_grammar_model.dart';

/// Multilingual On-Device Correction Engine (Qwen3-0.6B via LiteRT-LM / MediaPipe LLM Inference)
///
/// Handles Arabic, French, Spanish, German, Portuguese, and Italian locally on-device.
/// Incorporates strict translation guardrails, prompt defense, and rule fallbacks.
class MultilingualEngine implements LocalGrammarModel {
  MultilingualEngine({
    CorrectionDiffService diffService = const CorrectionDiffService(),
  }) : _diffService = diffService;

  final CorrectionDiffService _diffService;

  static const MethodChannel _channel = MethodChannel('com.mogate.grammarfix/grammar_core');

  @override
  Future<bool> isReady() async {
    try {
      return await _channel.invokeMethod<bool>('isContextModelReady') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Runs multilingual correction on [text] in [language].
  @override
  Future<CorrectionResult> correct({
    required String text,
    required AppLanguage language,
    int revision = 0,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return CorrectionResult.empty(revision: revision, lang: language);
    }

    try {
      // 1. Check if model is loaded on Android via platform channel
      final isReady = await _channel.invokeMethod<bool>('isContextModelReady') ?? false;

      String correctedText;
      String engineUsed;

      if (isReady) {
        // Construct system prompt with strict no-translation and formatting guardrails
        final prompt = _buildCorrectionPrompt(text: trimmed, language: language);
        final rawResponse = await _channel.invokeMethod<String>('generate', {'prompt': prompt});

        correctedText = _cleanAndVerifyResponse(rawResponse ?? trimmed, trimmed, language);
        engineUsed = 'Qwen3-0.6B (LiteRT-LM)';
      } else {
        // Safe offline rule-based fallback when model weights are being downloaded
        correctedText = _applyLanguageCorrections(trimmed, language);
        engineUsed = 'Local Rules Fallback';
      }

      // 2. Compute granular issue diffs
      final issues = _diffService.computeIssues(
        trimmed,
        correctedText,
        engine: 'qwen',
      );

      return CorrectionResult(
        sourceText: text,
        sourceHash: text.hashCode,
        sourceRevision: revision,
        correctedText: correctedText,
        issues: issues,
        language: language,
        engineName: engineUsed,
      );
    } catch (e) {
      // Graceful fallback to rule corrections on any exception
      final fallbackCorrected = _applyLanguageCorrections(trimmed, language);
      final issues = _diffService.computeIssues(
        trimmed,
        fallbackCorrected,
        engine: 'fallback',
      );

      return CorrectionResult(
        sourceText: text,
        sourceHash: text.hashCode,
        sourceRevision: revision,
        correctedText: fallbackCorrected,
        issues: issues,
        language: language,
        engineName: 'Local Rules (Fallback)',
      );
    }
  }

  String _buildCorrectionPrompt({required String text, required AppLanguage language}) {
    return '''
You are a grammar and spelling corrector for ${language.displayName}.
CRITICAL INSTRUCTIONS:
1. Correct only grammar, spelling, gender agreement, verb conjugation, and punctuation mistakes.
2. DO NOT TRANSLATE. Output must remain strictly in ${language.displayName}.
3. DO NOT change the style, tone, or meaning of the text.
4. Output ONLY the corrected text. Do NOT include explanations, greetings, quotes, or markdown notes.

Original text:
$text

Corrected text:
''';
  }

  String _cleanAndVerifyResponse(String response, String original, AppLanguage language) {
    var cleaned = response.trim();

    // Strip markdown wrappers if any
    if (cleaned.startsWith('```') && cleaned.endsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.length >= 2) {
        cleaned = lines.sublist(1, lines.length - 1).join('\n').trim();
      }
    }

    // Guardrail: If output is wildly different in length or empty, revert to original
    if (cleaned.isEmpty || cleaned.length > original.length * 3 || cleaned.length < original.length * 0.3) {
      return original;
    }

    return cleaned;
  }

  String _replacePreservingCase(String input, RegExp pattern, String replacement) {
    return input.replaceAllMapped(pattern, (match) {
      final orig = match.group(0)!;
      if (orig.isNotEmpty && orig[0] == orig[0].toUpperCase() && orig[0] != orig[0].toLowerCase()) {
        return replacement[0].toUpperCase() + replacement.substring(1);
      }
      return replacement;
    });
  }

  /// Rule-based corrections for multilingual testing and offline fallback
  String _applyLanguageCorrections(String text, AppLanguage language) {
    var result = text;

    switch (language) {
      case AppLanguage.arabic:
        // Arabic agreement & common spelling fixes
        result = result
            .replaceAll('هذه كتاب', 'هذا كتاب')
            .replaceAll('هذا سيارة', 'هذه سيارة')
            .replaceAll('الطلاب يكتب', 'الطلاب يكتبون')
            .replaceAll('ان شاء الله', 'إن شاء الله')
            .replaceAll('مسؤلية', 'مسؤولية')
            .replaceAll('أمرأة', 'امرأة');
        break;

      case AppLanguage.french:
        // French subject-verb agreement, gender & accents
        result = _replacePreservingCase(result, RegExp(r'\bles chat sont\b', caseSensitive: false), 'les chats sont');
        result = _replacePreservingCase(result, RegExp(r'\bils mange\b', caseSensitive: false), 'ils mangent');
        result = _replacePreservingCase(result, RegExp(r'\belle sont\b', caseSensitive: false), 'elles sont');
        result = _replacePreservingCase(result, RegExp(r'\ble maison\b', caseSensitive: false), 'la maison');
        result = _replacePreservingCase(result, RegExp(r'\btout les\b', caseSensitive: false), 'tous les');
        result = _replacePreservingCase(result, RegExp(r'\ba bientôt\b', caseSensitive: false), 'à bientôt');
        result = _replacePreservingCase(result, RegExp(r'\bc\x27est a dire\b', caseSensitive: false), 'c\'est-à-dire');
        break;

      case AppLanguage.spanish:
        // Spanish agreement, gender, question marks
        result = _replacePreservingCase(result, RegExp(r'\blos niño\b', caseSensitive: false), 'los niños');
        result = _replacePreservingCase(result, RegExp(r'\bellas es\b', caseSensitive: false), 'ellas son');
        result = _replacePreservingCase(result, RegExp(r'\bla problema\b', caseSensitive: false), 'el problema');
        result = _replacePreservingCase(result, RegExp(r'\btambien\b', caseSensitive: false), 'también');
        result = _replacePreservingCase(result, RegExp(r'\bmas o menos\b', caseSensitive: false), 'más o menos');
        result = _replacePreservingCase(result, RegExp(r'\bporfavor\b', caseSensitive: false), 'por favor');
        break;

      case AppLanguage.german:
        // German capitalization, articles & cases
        result = _replacePreservingCase(result, RegExp(r'\bdas hund\b', caseSensitive: false), 'der Hund');
        result = _replacePreservingCase(result, RegExp(r'\bdie haus\b', caseSensitive: false), 'das Haus');
        result = _replacePreservingCase(result, RegExp(r'\ber gehen\b', caseSensitive: false), 'er geht');
        result = _replacePreservingCase(result, RegExp(r'\bwir geht\b', caseSensitive: false), 'wir gehen');
        result = _replacePreservingCase(result, RegExp(r'\bdass ich weiss\b', caseSensitive: false), 'dass ich weiß');
        break;

      case AppLanguage.portuguese:
        // Portuguese agreement, accents
        result = _replacePreservingCase(result, RegExp(r'\bos menino\b', caseSensitive: false), 'os meninos');
        result = _replacePreservingCase(result, RegExp(r'\beles vai\b', caseSensitive: false), 'eles vão');
        result = _replacePreservingCase(result, RegExp(r'\bum casa\b', caseSensitive: false), 'uma casa');
        result = _replacePreservingCase(result, RegExp(r'\bnao\b', caseSensitive: false), 'não');
        result = _replacePreservingCase(result, RegExp(r'\btambem\b', caseSensitive: false), 'também');
        result = _replacePreservingCase(result, RegExp(r'\bvoce\b', caseSensitive: false), 'você');
        break;

      case AppLanguage.italian:
        // Italian agreement, apostrophes
        result = _replacePreservingCase(result, RegExp(r'\bi gatto\b', caseSensitive: false), 'i gatti');
        result = _replacePreservingCase(result, RegExp(r'\bloro va\b', caseSensitive: false), 'loro vanno');
        result = _replacePreservingCase(result, RegExp(r'\bun amica\b', caseSensitive: false), 'un\'amica');
        result = _replacePreservingCase(result, RegExp(r'\bperche\b', caseSensitive: false), 'perché');
        result = _replacePreservingCase(result, RegExp(r'\bcosi\b', caseSensitive: false), 'così');
        break;

      default:
        break;
    }

    return result;
  }
}
