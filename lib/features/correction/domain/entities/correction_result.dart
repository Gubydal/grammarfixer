import 'correction_issue.dart';
import 'language.dart';

class CorrectionResult {
  const CorrectionResult({
    required this.sourceText,
    required this.sourceHash,
    required this.sourceRevision,
    required this.correctedText,
    required this.issues,
    required this.language,
    required this.engineName,
    this.latencyMs = 0,
    this.charCount = 0,
    this.wordCount = 0,
  });

  final String sourceText;
  final int sourceHash;
  final int sourceRevision;
  final String correctedText;
  final List<CorrectionIssue> issues;
  final AppLanguage language;
  final String engineName;
  final int latencyMs;
  final int charCount;
  final int wordCount;

  bool get hasIssues => issues.isNotEmpty;
  int get activeIssueCount => issues.where((i) => !i.isIgnored && !i.isApplied).length;
  bool get isClean => activeIssueCount == 0;

  CorrectionResult copyWith({
    String? sourceText,
    int? sourceHash,
    int? sourceRevision,
    String? correctedText,
    List<CorrectionIssue>? issues,
    AppLanguage? language,
    String? engineName,
    int? latencyMs,
    int? charCount,
    int? wordCount,
  }) {
    return CorrectionResult(
      sourceText: sourceText ?? this.sourceText,
      sourceHash: sourceHash ?? this.sourceHash,
      sourceRevision: sourceRevision ?? this.sourceRevision,
      correctedText: correctedText ?? this.correctedText,
      issues: issues ?? this.issues,
      language: language ?? this.language,
      engineName: engineName ?? this.engineName,
      latencyMs: latencyMs ?? this.latencyMs,
      charCount: charCount ?? this.charCount,
      wordCount: wordCount ?? this.wordCount,
    );
  }

  static CorrectionResult empty({int revision = 0, AppLanguage lang = AppLanguage.english}) {
    return CorrectionResult(
      sourceText: '',
      sourceHash: 0,
      sourceRevision: revision,
      correctedText: '',
      issues: const [],
      language: lang,
      engineName: 'none',
    );
  }
}
