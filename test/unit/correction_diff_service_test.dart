import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/domain/services/correction_diff_service.dart';

void main() {
  group('CorrectionDiffService', () {
    const diffService = CorrectionDiffService();

    test('returns empty issues when strings are identical', () {
      final issues = diffService.computeIssues('Hello world', 'Hello world');
      expect(issues, isEmpty);
    });

    test('identifies single word replacement (sont -> est)', () {
      const original = 'Le chat sont mignon';
      const corrected = 'Le chat est mignon';
      final issues = diffService.computeIssues(original, corrected);

      expect(issues, isNotEmpty);
      expect(issues.first.original, 'sont');
      expect(issues.first.topSuggestion, 'est');
    });

    test('identifies Arabic word replacement (هذه -> هذا)', () {
      const original = 'هذه كتاب مفيد';
      const corrected = 'هذا كتاب مفيد';
      final issues = diffService.computeIssues(original, corrected);

      expect(issues, isNotEmpty);
      expect(issues.first.original, 'هذه');
      expect(issues.first.topSuggestion, 'هذا');
    });

    test('identifies insertions and deletions correctly', () {
      const original = 'I apple.';
      const corrected = 'I ate an apple.';
      final issues = diffService.computeIssues(original, corrected);

      expect(issues, isNotEmpty);
    });
  });
}
