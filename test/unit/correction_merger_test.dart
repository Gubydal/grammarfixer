import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/domain/entities/correction_issue.dart';
import 'package:grammarfix/features/correction/domain/entities/correction_mode.dart';
import 'package:grammarfix/features/correction/domain/entities/writing_style_profile.dart';
import 'package:grammarfix/features/correction/domain/services/correction_merger.dart';
import 'package:grammarfix/features/correction/domain/services/protected_span_detector.dart';

void main() {
  group('CorrectionMerger Tests', () {
    const merger = CorrectionMerger();

    test('deduplicates overlapping suggestions prioritizing high confidence', () {
      const text = 'I recieved the package.';
      final typoIssue = CorrectionIssue(
        id: '1',
        engine: 'typo',
        category: IssueCategory.spelling,
        severity: IssueSeverity.warning,
        confidence: IssueConfidence.high,
        start: 2,
        end: 10,
        original: 'recieved',
        suggestions: ['received'],
        message: 'Typo error',
      );

      final modelIssue = CorrectionIssue(
        id: '2',
        engine: 'qwen',
        category: IssueCategory.spelling,
        severity: IssueSeverity.warning,
        confidence: IssueConfidence.medium,
        start: 2,
        end: 10,
        original: 'recieved',
        suggestions: ['received'],
        message: 'Model diff',
      );

      final merged = merger.merge(
        text: text,
        typoIssues: [typoIssue],
        harperIssues: [],
        modelIssues: [modelIssue],
        styleProfile: const WritingStyleProfile(),
        mode: CorrectionMode.correct,
      );

      expect(merged.length, 1);
      expect(merged.first.confidence, IssueConfidence.high);
    });

    test('enforces protected spans and filters out invalid suggestions', () {
      const text = 'Email john@example.com immediately.';
      final protectedSpans = ProtectedSpanDetector.detect(text);

      final badModelIssue = CorrectionIssue(
        id: '1',
        engine: 'qwen',
        category: IssueCategory.spelling,
        severity: IssueSeverity.warning,
        confidence: IssueConfidence.low,
        start: 6,
        end: 22,
        original: 'john@example.com',
        suggestions: ['john_doe@example.com'],
        message: 'Invalid rewrite',
      );

      final merged = merger.merge(
        text: text,
        typoIssues: [],
        harperIssues: [],
        modelIssues: [badModelIssue],
        styleProfile: const WritingStyleProfile(),
        mode: CorrectionMode.correct,
        protectedSpans: protectedSpans,
      );

      expect(merged.isEmpty, isTrue);
    });

    test('objective grammar cannot be personalized away', () {
      const text = 'The dogs is outside.';
      final grammarIssue = CorrectionIssue(
        id: '1',
        engine: 'harper',
        category: IssueCategory.agreement,
        severity: IssueSeverity.warning,
        confidence: IssueConfidence.high,
        start: 0,
        end: 11,
        original: 'The dogs is',
        suggestions: ['The dogs are'],
        message: 'Subject-verb agreement',
      );

      // Even if user rejected a style pattern, objective grammar remains active
      const styleProfile = WritingStyleProfile(
        rejectedStylePatterns: {'the dogs is->the dogs are'},
      );

      final merged = merger.merge(
        text: text,
        typoIssues: [],
        harperIssues: [grammarIssue],
        modelIssues: [],
        styleProfile: styleProfile,
        mode: CorrectionMode.correct,
      );

      expect(merged.length, 1);
      expect(merged.first.topSuggestion, 'The dogs are');
    });
  });
}
