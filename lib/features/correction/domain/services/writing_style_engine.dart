import '../entities/correction_issue.dart';
import '../entities/correction_mode.dart';
import '../entities/writing_style_profile.dart';
import 'protected_span_detector.dart';

/// On-device writing style and tone enhancement engine.
/// Provides suggestions for Formality (Professional vs Casual), Concision, Academic vocabulary,
/// Contraction preferences, and Oxford commas.
class WritingStyleEngine {
  const WritingStyleEngine();

  List<CorrectionIssue> findStyleIssues({
    required String text,
    required WritingStyleProfile profile,
    required CorrectionMode mode,
    List<ProtectedSpan> protectedSpans = const [],
  }) {
    if (text.trim().isEmpty) return const [];

    final issues = <CorrectionIssue>[];

    // 1. Concision & Redundancy (always active in Improve mode)
    if (mode == CorrectionMode.improve) {
      _checkConcision(text, issues, protectedSpans);
    }

    // 2. Formality & Tone (Professional, Casual, Academic)
    _checkFormality(text, profile, mode, issues, protectedSpans);

    // 3. Contraction preferences
    _checkContractions(text, profile, issues, protectedSpans);

    // 4. Oxford comma
    _checkOxfordComma(text, profile, issues, protectedSpans);

    return issues;
  }

  void _checkConcision(
    String text,
    List<CorrectionIssue> issues,
    List<ProtectedSpan> protectedSpans,
  ) {
    const concisionMap = {
      'in order to': 'to',
      'at this point in time': 'now',
      'due to the fact that': 'because',
      'for the purpose of': 'for',
      'in the event that': 'if',
      'with regard to': 'regarding',
      'is able to': 'can',
      'has the ability to': 'can',
      'has the capability to': 'can',
      'a majority of': 'most',
      'a number of': 'several',
      'at all times': 'always',
      'at the present time': 'currently',
      'in spite of the fact that': 'although',
      'until such time as': 'until',
      'prior to': 'before',
      'subsequent to': 'after',
    };

    for (final entry in concisionMap.entries) {
      final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        final start = match.start;
        final end = match.end;
        final orig = match.group(0)!;
        if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
            !issues.any((i) => i.start <= start && i.end >= end)) {
          final repl = orig[0] == orig[0].toUpperCase()
              ? entry.value[0].toUpperCase() + entry.value.substring(1)
              : entry.value;

          issues.add(CorrectionIssue(
            id: 'style_concise_${start}_$end',
            engine: 'style',
            category: IssueCategory.clarity,
            severity: IssueSeverity.suggestion,
            confidence: IssueConfidence.high,
            start: start,
            end: end,
            original: orig,
            suggestions: [repl],
            message: 'Simplify phrasing: replace "$orig" with "$repl".',
            shortReason: 'Concision',
            isAutoFixable: false,
          ));
        }
      }
    }
  }

  void _checkFormality(
    String text,
    WritingStyleProfile profile,
    CorrectionMode mode,
    List<CorrectionIssue> issues,
    List<ProtectedSpan> protectedSpans,
  ) {
    final formality = profile.formalityPreference;

    // Professional / Formal enhancements (active in Improve mode or when formality == formal)
    if (formality == FormalityStyle.formal || mode == CorrectionMode.improve) {
      const professionalMap = {
        'tell me': 'please let me know',
        'a lot of': 'numerous',
        'very good': 'excellent',
        'very bad': 'unfavorable',
        'get in touch': 'contact',
        'sorry for the delay': 'thank you for your patience',
        'need help': 'require assistance',
        'asap': 'at your earliest convenience',
        'can we be friend': 'would you like to connect?',
        'can we be friends': 'would you like to connect?',
        'wanna': 'want to',
        'gonna': 'going to',
        'gotta': 'need to',
        'kinda': 'somewhat',
        'sorta': 'somewhat',
        'no problem': 'you are welcome',
      };

      for (final entry in professionalMap.entries) {
        final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false);
        for (final match in pattern.allMatches(text)) {
          final start = match.start;
          final end = match.end;
          final orig = match.group(0)!;
          if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
              !issues.any((i) => i.start <= start && i.end >= end)) {
            final repl = orig[0] == orig[0].toUpperCase()
                ? entry.value[0].toUpperCase() + entry.value.substring(1)
                : entry.value;

            issues.add(CorrectionIssue(
              id: 'style_formal_${start}_$end',
              engine: 'style',
              category: IssueCategory.style,
              severity: IssueSeverity.suggestion,
              confidence: IssueConfidence.medium,
              start: start,
              end: end,
              original: orig,
              suggestions: [repl],
              message: 'Professional tone: consider using "$repl" instead of "$orig".',
              shortReason: 'Tone polish',
              isAutoFixable: false,
            ));
          }
        }
      }
    }

    // Casual / Friendly enhancements (when formality == casual)
    if (formality == FormalityStyle.casual) {
      const casualMap = {
        'furthermore': 'also',
        'nevertheless': 'anyway',
        'subsequently': 'after that',
        'commence': 'start',
        'terminate': 'end',
        'utilize': 'use',
        'inquire': 'ask',
      };

      for (final entry in casualMap.entries) {
        final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false);
        for (final match in pattern.allMatches(text)) {
          final start = match.start;
          final end = match.end;
          final orig = match.group(0)!;
          if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
              !issues.any((i) => i.start <= start && i.end >= end)) {
            final repl = orig[0] == orig[0].toUpperCase()
                ? entry.value[0].toUpperCase() + entry.value.substring(1)
                : entry.value;

            issues.add(CorrectionIssue(
              id: 'style_casual_${start}_$end',
              engine: 'style',
              category: IssueCategory.style,
              severity: IssueSeverity.suggestion,
              confidence: IssueConfidence.medium,
              start: start,
              end: end,
              original: orig,
              suggestions: [repl],
              message: 'Casual tone: replace "$orig" with "$repl".',
              shortReason: 'Casual tone',
              isAutoFixable: false,
            ));
          }
        }
      }
    }
  }

  void _checkContractions(
    String text,
    WritingStyleProfile profile,
    List<CorrectionIssue> issues,
    List<ProtectedSpan> protectedSpans,
  ) {
    if (profile.contractionsPreference == ContractionStyle.preferExpanded) {
      // Expand contractions (e.g. don't -> do not, can't -> cannot)
      const expansionMap = {
        "don't": "do not",
        "can't": "cannot",
        "won't": "will not",
        "didn't": "did not",
        "isn't": "is not",
        "aren't": "are not",
        "wasn't": "was not",
        "weren't": "were not",
        "hasn't": "has not",
        "haven't": "have not",
        "hadn't": "had not",
        "shouldn't": "should not",
        "wouldn't": "would not",
        "couldn't": "could not",
        "it's": "it is",
        "I'm": "I am",
        "you're": "you are",
        "they're": "they are",
        "we're": "we are",
      };

      for (final entry in expansionMap.entries) {
        final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false);
        for (final match in pattern.allMatches(text)) {
          final start = match.start;
          final end = match.end;
          final orig = match.group(0)!;
          if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
              !issues.any((i) => i.start <= start && i.end >= end)) {
            final repl = orig[0] == orig[0].toUpperCase()
                ? entry.value[0].toUpperCase() + entry.value.substring(1)
                : entry.value;

            issues.add(CorrectionIssue(
              id: 'style_expand_${start}_$end',
              engine: 'style',
              category: IssueCategory.style,
              severity: IssueSeverity.suggestion,
              confidence: IssueConfidence.high,
              start: start,
              end: end,
              original: orig,
              suggestions: [repl],
              message: 'Formal style: expand contraction "$orig" to "$repl".',
              shortReason: 'Formality',
              isAutoFixable: false,
            ));
          }
        }
      }
    } else if (profile.contractionsPreference == ContractionStyle.preferContractions) {
      // Use contractions (e.g. do not -> don't)
      const contractionMap = {
        "do not": "don't",
        "cannot": "can't",
        "will not": "won't",
        "did not": "didn't",
        "is not": "isn't",
        "are not": "aren't",
        "was not": "wasn't",
        "were not": "weren't",
        "has not": "hasn't",
        "have not": "haven't",
        "had not": "hadn't",
        "should not": "shouldn't",
        "would not": "wouldn't",
        "could not": "couldn't",
        "it is": "it's",
        "I am": "I'm",
        "you are": "you're",
        "they are": "they're",
        "we are": "we're",
      };

      for (final entry in contractionMap.entries) {
        final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false);
        for (final match in pattern.allMatches(text)) {
          final start = match.start;
          final end = match.end;
          final orig = match.group(0)!;
          if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
              !issues.any((i) => i.start <= start && i.end >= end)) {
            final repl = orig[0] == orig[0].toUpperCase()
                ? entry.value[0].toUpperCase() + entry.value.substring(1)
                : entry.value;

            issues.add(CorrectionIssue(
              id: 'style_contract_${start}_$end',
              engine: 'style',
              category: IssueCategory.style,
              severity: IssueSeverity.suggestion,
              confidence: IssueConfidence.high,
              start: start,
              end: end,
              original: orig,
              suggestions: [repl],
              message: 'Natural style: use contraction "$repl" instead of "$orig".',
              shortReason: 'Contraction',
              isAutoFixable: false,
            ));
          }
        }
      }
    }
  }

  void _checkOxfordComma(
    String text,
    WritingStyleProfile profile,
    List<CorrectionIssue> issues,
    List<ProtectedSpan> protectedSpans,
  ) {
    if (profile.oxfordCommaPreference == OxfordCommaStyle.always) {
      // Find 3-item lists missing serial comma: e.g. "A, B and C" -> "A, B, and C"
      final pattern = RegExp(r'(\b[a-zA-Z]+,\s+[a-zA-Z]+)\s+(and|or)\s+([a-zA-Z]+)', caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        final orig = match.group(0)!;
        final start = match.start;
        final end = match.end;
        if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
            !issues.any((i) => i.start <= start && i.end >= end)) {
          final repl = '${match.group(1)!}, ${match.group(2)!} ${match.group(3)!}';
          issues.add(CorrectionIssue(
            id: 'style_oxford_${start}_$end',
            engine: 'style',
            category: IssueCategory.punctuation,
            severity: IssueSeverity.suggestion,
            confidence: IssueConfidence.high,
            start: start,
            end: end,
            original: orig,
            suggestions: [repl],
            message: 'Add an Oxford (serial) comma before "${match.group(2)}".',
            shortReason: 'Oxford comma',
            isAutoFixable: false,
          ));
        }
      }
    }
  }
}
