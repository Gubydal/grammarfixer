import '../../domain/entities/correction_issue.dart';
import '../../domain/entities/correction_mode.dart';
import '../../domain/entities/correction_result.dart';
import '../../domain/entities/language.dart';

sealed class CorrectionState {
  const CorrectionState();
}

class CorrectionInitial extends CorrectionState {
  const CorrectionInitial({
    this.text = '',
    this.selectedLanguage = AppLanguage.auto,
    this.mode = CorrectionMode.correct,
  });

  final String text;
  final AppLanguage selectedLanguage;
  final CorrectionMode mode;
}

/// Represents a single auto-fix that was applied live (for display + undo).
class LiveAutoFix {
  const LiveAutoFix({
    required this.original,
    required this.replacement,
    required this.reason,
    required this.start,
    required this.end,
    required this.timestamp,
  });

  final String original;
  final String replacement;
  final String reason;
  final int start;
  final int end;
  final DateTime timestamp;
}

class CorrectionEditing extends CorrectionState {
  const CorrectionEditing({
    required this.text,
    this.selectedLanguage = AppLanguage.auto,
    this.detectedLanguage = AppLanguage.english,
    this.mode = CorrectionMode.correct,
    this.liveIssues = const [],
    this.lastAutoFix,
    this.isLiveChecking = false,
  });

  final String text;
  final AppLanguage selectedLanguage;
  final AppLanguage detectedLanguage;
  final CorrectionMode mode;

  /// Issues found by live/debounced checking (shown inline, not in review mode).
  final List<CorrectionIssue> liveIssues;

  /// Most recent auto-fix applied (for explanation bar + undo).
  final LiveAutoFix? lastAutoFix;

  /// Whether a live check is currently in progress.
  final bool isLiveChecking;

  bool get isRtl => selectedLanguage.isRtl || (selectedLanguage == AppLanguage.auto && detectedLanguage.isRtl);
  int get charCount => text.length;
  int get wordCount => text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  int get activeLiveIssueCount => liveIssues.where((i) => !i.isIgnored && !i.isApplied).length;
}

class CorrectionProcessing extends CorrectionState {
  const CorrectionProcessing({
    required this.text,
    required this.language,
    this.mode = CorrectionMode.correct,
  });

  final String text;
  final AppLanguage language;
  final CorrectionMode mode;
}

class CorrectionReview extends CorrectionState {
  const CorrectionReview({
    required this.sourceText,
    required this.currentText,
    required this.result,
    required this.issues,
    this.selectedIssue,
    required this.language,
    this.mode = CorrectionMode.correct,
    this.isFixedAll = false,
    this.isBeforeAfterVisible = false,
    this.undoStack = const [],
  });

  final String sourceText;
  final String currentText;
  final CorrectionResult result;
  final List<CorrectionIssue> issues;
  final CorrectionIssue? selectedIssue;
  final AppLanguage language;
  final CorrectionMode mode;
  final bool isFixedAll;
  final bool isBeforeAfterVisible;
  final List<String> undoStack;

  bool get isRtl => language.isRtl;
  int get activeIssueCount => issues.where((i) => !i.isIgnored && !i.isApplied).length;
  bool get isClean => activeIssueCount == 0;
  bool get canUndo => undoStack.isNotEmpty;

  /// Human-friendly summary string (e.g. "5 fixes: 2 grammar · 2 spelling · 1 punctuation")
  String get summaryDescription {
    final active = issues.where((i) => !i.isIgnored).toList();
    if (active.isEmpty) return 'No issues found';

    final grammarCount = active.where((i) => i.category == IssueCategory.grammar || i.category == IssueCategory.agreement || i.category == IssueCategory.tense).length;
    final spellingCount = active.where((i) => i.category == IssueCategory.spelling || i.category == IssueCategory.wordBoundary).length;
    final punctCount = active.where((i) => i.category == IssueCategory.punctuation).length;
    final otherCount = active.length - (grammarCount + spellingCount + punctCount);

    final parts = <String>[];
    if (grammarCount > 0) parts.add('$grammarCount grammar');
    if (spellingCount > 0) parts.add('$spellingCount spelling');
    if (punctCount > 0) parts.add('$punctCount punctuation');
    if (otherCount > 0) parts.add('$otherCount other');

    return '${active.length} fixes: ${parts.join(' · ')}';
  }
}

class CorrectionLanguagePackRequired extends CorrectionState {
  const CorrectionLanguagePackRequired({
    required this.language,
    required this.text,
  });

  final AppLanguage language;
  final String text;
}

class CorrectionError extends CorrectionState {
  const CorrectionError({
    required this.message,
    required this.text,
    required this.language,
  });

  final String message;
  final String text;
  final AppLanguage language;
}
