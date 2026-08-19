import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/domain/entities/correction_issue.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';

void main() {
  group('HarperEngine (English On-Device)', () {
    late HarperEngine engine;

    setUp(() {
      engine = HarperEngine(dialect: EnglishDialect.american);
    });

    test('corrects subject-verb agreement (he don\'t -> he doesn\'t)', () {
      final result = engine.lint(text: 'He don\'t understand.');
      expect(result.issues, isNotEmpty);
      expect(
        result.issues.first.category == IssueCategory.agreement ||
            result.issues.first.category == IssueCategory.grammar,
        isTrue,
      );
      expect(result.correctedText, 'He doesn\'t understand.');
    });

    test('corrects indefinite article (a apple -> an apple)', () {
      final result = engine.lint(text: 'She ate a apple today.');
      expect(result.issues, isNotEmpty);
      expect(result.correctedText, 'She ate an apple today.');
    });

    test('corrects common spelling error (teh -> the, recieve -> receive)', () {
      final result = engine.lint(text: 'I will recieve teh package.');
      expect(result.issues.length, 2);
      expect(result.issues.any((i) => i.original == 'recieve'), isTrue);
      expect(result.issues.any((i) => i.original == 'teh'), isTrue);
      expect(result.correctedText, 'I will receive the package.');
    });

    test('respects custom user dictionary words', () {
      engine.addUserWord('Mogate');
      final result = engine.lint(text: 'Welcome to Mogate platform.');
      expect(result.issues.any((i) => i.original == 'Mogate'), isFalse);
    });

    test('handles empty and whitespace-only text safely', () {
      final result = engine.lint(text: '   ');
      expect(result.issues, isEmpty);
      expect(result.correctedText, '');
    });

    test('handles repeated words (the the -> the)', () {
      final result = engine.lint(text: 'This is the the best day.');
      expect(result.issues, isNotEmpty);
      expect(result.issues.first.category, IssueCategory.clarity);
    });
  });
}
