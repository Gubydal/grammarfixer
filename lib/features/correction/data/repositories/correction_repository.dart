import '../../domain/entities/correction_issue.dart';
import '../../domain/entities/correction_mode.dart';
import '../../domain/entities/correction_result.dart';
import '../../domain/entities/language.dart';
import '../../domain/services/correction_merger.dart';
import '../../domain/services/harper_engine.dart';
import '../../domain/services/language_detector.dart';
import '../../domain/services/multilingual_engine.dart';
import '../../domain/services/protected_span_detector.dart';
import '../../domain/services/typo_candidate_engine.dart';
import 'custom_dictionary_repository.dart';
import 'model_pack_repository.dart';
import 'personal_style_repository.dart';

class CorrectionRepository {
  CorrectionRepository({
    required HarperEngine harperEngine,
    required MultilingualEngine multilingualEngine,
    required LanguageDetector languageDetector,
    required CustomDictionaryRepository customDictionaryRepo,
    required ModelPackRepository modelPackRepo,
    required PersonalStyleRepository personalStyleRepo,
    TypoCandidateEngine? typoCandidateEngine,
    CorrectionMerger? correctionMerger,
  })  : _harper = harperEngine,
        _multilingual = multilingualEngine,
        _detector = languageDetector,
        _dictionary = customDictionaryRepo,
        _modelPack = modelPackRepo,
        _personalStyle = personalStyleRepo,
        _typoEngine = typoCandidateEngine ?? TypoCandidateEngine(),
        _merger = correctionMerger ?? const CorrectionMerger() {
    _syncUserDictionary();
  }

  final HarperEngine _harper;
  final MultilingualEngine _multilingual;
  final LanguageDetector _detector;
  final CustomDictionaryRepository _dictionary;
  final ModelPackRepository _modelPack;
  final PersonalStyleRepository _personalStyle;
  final TypoCandidateEngine _typoEngine;
  final CorrectionMerger _merger;

  int _latestRevision = 0;
  int get latestRevision => _latestRevision;

  void _syncUserDictionary() {
    final words = _dictionary.getWords();
    _harper.clearUserWords();
    for (final w in words) {
      _harper.addUserWord(w);
    }
    _typoEngine.setUserDictionary(words);
  }

  void setEnglishDialect(EnglishDialect dialect) {
    _harper.setDialect(dialect);
    _personalStyle.updateDialect(dialect);
  }

  Future<void> addUserWord(String word) async {
    await _dictionary.addWord(word);
    _syncUserDictionary();
  }

  Future<void> removeUserWord(String word) async {
    await _dictionary.removeWord(word);
    _syncUserDictionary();
  }

  /// Runs multi-layer grammar, spelling, typo, and context correction on [text].
  Future<CorrectionResult> correct({
    required String text,
    AppLanguage selectedLanguage = AppLanguage.auto,
    CorrectionMode mode = CorrectionMode.correct,
    int? revision,
  }) async {
    if (revision != null && revision > _latestRevision) {
      _latestRevision = revision;
    }
    final currentRevision = revision ?? ++_latestRevision;
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return CorrectionResult.empty(
        revision: currentRevision,
        lang: selectedLanguage == AppLanguage.auto ? AppLanguage.english : selectedLanguage,
      );
    }

    final startTime = DateTime.now();

    // 1. Detect and protect non-text spans (URLs, emails, code blocks, hashtags, etc.)
    final protectedSpans = ProtectedSpanDetector.detect(text);

    // 2. Determine target language
    AppLanguage targetLanguage = selectedLanguage;
    if (selectedLanguage == AppLanguage.auto) {
      final detected = _detector.detect(text);
      targetLanguage = detected.language;
    }

    final styleProfile = _personalStyle.profile;

    // 3. Multi-layer candidate generation
    List<CorrectionIssue> typoIssues = [];
    List<CorrectionIssue> harperIssues = [];
    List<CorrectionIssue> modelIssues = [];

    if (targetLanguage == AppLanguage.english) {
      // Layer A: Fast typo & word-boundary engine
      typoIssues = _typoEngine.findTypoIssues(
        text,
        language: targetLanguage,
        dialect: styleProfile.dialect,
        protectedSpans: protectedSpans,
      );

      // Layer B: Harper deterministic rules
      final harperResult = _harper.lint(
        text: text,
        revision: currentRevision,
        protectedSpans: protectedSpans,
      );
      harperIssues = harperResult.issues;

      // Layer C: Contextual local model (if model pack is installed)
      if (_modelPack.currentState.isInstalled) {
        try {
          final qwenResult = await _multilingual.correct(
            text: text,
            language: targetLanguage,
            revision: currentRevision,
          );
          modelIssues = qwenResult.issues;
        } catch (_) {
          // Model error ignored; typo + Harper provide full offline English coverage
        }
      }
    } else {
      // Non-English: check if multilingual pack is installed
      if (!_modelPack.currentState.isInstalled) {
        return CorrectionResult(
          sourceText: text,
          sourceHash: text.hashCode,
          sourceRevision: currentRevision,
          correctedText: text,
          issues: const [],
          language: targetLanguage,
          engineName: 'Language Pack Required',
        );
      }

      final qwenResult = await _multilingual.correct(
        text: text,
        language: targetLanguage,
        revision: currentRevision,
      );
      modelIssues = qwenResult.issues;
    }

    // 4. Correction Merger: deduplicate, rank, enforce protected spans & style profile
    final unifiedIssues = _merger.merge(
      text: text,
      typoIssues: typoIssues,
      harperIssues: harperIssues,
      modelIssues: modelIssues,
      styleProfile: styleProfile,
      mode: mode,
      protectedSpans: protectedSpans,
    );

    // 5. Revision Safety check
    if (currentRevision < _latestRevision) {
      return CorrectionResult.empty(revision: _latestRevision, lang: targetLanguage);
    }

    final correctedText = applyFixAll(text, unifiedIssues);
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;

    return CorrectionResult(
      sourceText: text,
      sourceHash: text.hashCode,
      sourceRevision: currentRevision,
      correctedText: correctedText,
      issues: unifiedIssues,
      language: targetLanguage,
      engineName: targetLanguage == AppLanguage.english
          ? (_modelPack.currentState.isInstalled ? 'Harper + Contextual Model' : 'Harper + Fast Typo Engine')
          : 'Qwen3-0.6B (LiteRT-LM)',
      latencyMs: elapsed,
      charCount: text.length,
      wordCount: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
    );
  }

  /// Deterministically applies all non-ignored top suggestions to [sourceText] from end to start.
  String applyFixAll(String sourceText, List<CorrectionIssue> issues) {
    final activeIssues = issues.where((i) => !i.isIgnored && !i.isApplied && i.suggestions.isNotEmpty).toList()
      ..sort((a, b) => b.start.compareTo(a.start)); // End to start to prevent offset shifting

    if (activeIssues.isEmpty) return sourceText;

    var result = sourceText;
    for (final issue in activeIssues) {
      if (issue.start >= 0 && issue.end <= result.length && issue.start <= issue.end) {
        result = result.replaceRange(issue.start, issue.end, issue.topSuggestion);
      }
    }

    return result;
  }

  /// Applies a single suggestion replacement to the text safely.
  String applySingleSuggestion(String sourceText, CorrectionIssue issue, String replacement) {
    if (issue.start < 0 || issue.end > sourceText.length || issue.start > issue.end) {
      return sourceText;
    }
    return sourceText.replaceRange(issue.start, issue.end, replacement);
  }
}
