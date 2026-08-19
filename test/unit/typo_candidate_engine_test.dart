import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/typo_candidate_engine.dart';

void main() {
  group('TypoCandidateEngine Tests', () {
    late TypoCandidateEngine engine;

    setUp(() {
      engine = TypoCandidateEngine();
    });

    test('fixes common misspellings and transpositions', () {
      const text = 'I recieved teh letter and thsi is becuase we care.';
      final issues = engine.findTypoIssues(
        text,
        language: AppLanguage.english,
        dialect: EnglishDialect.american,
      );

      expect(issues.any((i) => i.original == 'recieved' && i.topSuggestion == 'received'), isTrue);
      expect(issues.any((i) => i.original == 'teh' && i.topSuggestion == 'the'), isTrue);
      expect(issues.any((i) => i.original == 'thsi' && i.topSuggestion == 'this'), isTrue);
      expect(issues.any((i) => i.original == 'becuase' && i.topSuggestion == 'because'), isTrue);
    });

    test('collapses repeated characters while preserving valid double letters', () {
      const text = 'Hellooooo world, whatt a great coffee at the committee.';
      final issues = engine.findTypoIssues(
        text,
        language: AppLanguage.english,
        dialect: EnglishDialect.american,
      );

      // "Hellooooo" -> "Hello"
      expect(issues.any((i) => i.original == 'Hellooooo' && i.topSuggestion == 'Hello'), isTrue);
      // "whatt" -> "what"
      expect(issues.any((i) => i.original == 'whatt' && i.topSuggestion == 'what'), isTrue);
      // "coffee" and "committee" are valid and must NOT be flagged
      expect(issues.any((i) => i.original == 'coffee'), isFalse);
      expect(issues.any((i) => i.original == 'committee'), isFalse);
    });

    test('detects joined and split words', () {
      const text = 'I like this alot inthe morning, but some thing is strange.';
      final issues = engine.findTypoIssues(
        text,
        language: AppLanguage.english,
        dialect: EnglishDialect.american,
      );

      expect(issues.any((i) => i.original == 'alot' && i.topSuggestion == 'a lot'), isTrue);
      expect(issues.any((i) => i.original == 'inthe' && i.topSuggestion == 'in the'), isTrue);
      expect(issues.any((i) => i.original == 'some thing' && i.topSuggestion == 'something'), isTrue);
    });

    test('fixes missing apostrophes in common contractions', () {
      const text = 'They cant come and they didnt call, but they said theyre fine.';
      final issues = engine.findTypoIssues(
        text,
        language: AppLanguage.english,
        dialect: EnglishDialect.american,
      );

      expect(issues.any((i) => i.original == 'cant' && i.topSuggestion == "can't"), isTrue);
      expect(issues.any((i) => i.original == 'didnt' && i.topSuggestion == "didn't"), isTrue);
      expect(issues.any((i) => i.original == 'theyre' && i.topSuggestion == "they're"), isTrue);
    });

    test('respects user dictionary whitelisted words', () {
      engine.setUserDictionary({'teh', 'alot'});
      const text = 'I love teh product alot.';
      final issues = engine.findTypoIssues(
        text,
        language: AppLanguage.english,
        dialect: EnglishDialect.american,
      );

      expect(issues.any((i) => i.original == 'teh'), isFalse);
      expect(issues.any((i) => i.original == 'alot'), isFalse);
    });
  });
}
