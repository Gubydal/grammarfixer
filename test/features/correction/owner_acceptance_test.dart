import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/data/repositories/correction_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/model_pack_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/entities/correction_issue.dart';
import 'package:grammarfix/features/correction/domain/entities/correction_mode.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/entities/writing_style_profile.dart';
import 'package:grammarfix/features/correction/domain/services/english_context_rules.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';
import 'package:grammarfix/features/correction/domain/services/typo_candidate_engine.dart';
import 'package:grammarfix/features/correction/domain/services/writing_style_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CorrectionRepository repository;
  late EnglishContextRules contextRules;
  late TypoCandidateEngine typoEngine;
  late WritingStyleEngine styleEngine;
  late PersonalStyleRepository personalStyleRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final customDictRepo = CustomDictionaryRepository(prefs: prefs);
    final modelPackRepo = ModelPackRepository(prefs: prefs);
    personalStyleRepo = PersonalStyleRepository(prefs);

    contextRules = const EnglishContextRules();
    typoEngine = TypoCandidateEngine();
    styleEngine = const WritingStyleEngine();

    repository = CorrectionRepository(
      harperEngine: HarperEngine(),
      multilingualEngine: MultilingualEngine(),
      languageDetector: const LanguageDetector(),
      customDictionaryRepo: customDictRepo,
      modelPackRepo: modelPackRepo,
      personalStyleRepo: personalStyleRepo,
      typoCandidateEngine: typoEngine,
      contextRules: contextRules,
      styleEngine: styleEngine,
    );
  });

  test('EnglishContextRules correctly catches contextual homophones and agreement', () {
    // 1. "Your going" -> "You're"
    final r1 = contextRules.findIssues('Your going to like it.');
    expect(r1.isNotEmpty, isTrue);
    expect(r1.first.topSuggestion, equals("You're"));

    // 2. "Their coming" -> "They're"
    final r2 = contextRules.findIssues('Their coming over.');
    expect(r2.isNotEmpty, isTrue);
    expect(r2.first.topSuggestion, equals("They're"));

    // 3. "could of" -> "have"
    final r3 = contextRules.findIssues('You could of told me.');
    expect(r3.isNotEmpty, isTrue);
    expect(r3.first.topSuggestion, equals('have'));

    // 4. "better then" -> "than"
    final r4 = contextRules.findIssues('Better then nothing.');
    expect(r4.isNotEmpty, isTrue);
    expect(r4.first.topSuggestion, equals('than'));

    // 5. "I has" -> "have"
    final r5 = contextRules.findIssues('I has a car.');
    expect(r5.isNotEmpty, isTrue);
    expect(r5.first.topSuggestion, equals('have'));

    // 6. "have went" -> "gone"
    final r6 = contextRules.findIssues('I have went there.');
    expect(r6.isNotEmpty, isTrue);
    expect(r6.first.topSuggestion, equals('gone'));
  });

  test('Correction correctly handles informal and greeting sentences', () async {
    final result = await repository.correct(
      text: 'hi can we be friend',
      selectedLanguage: AppLanguage.english,
    );

    expect(result.issues.isNotEmpty, isTrue, reason: 'Issues must be detected in "hi can we be friend"');
    expect(result.correctedText, equals('Hi, can we be friends?'));
  });

  test('Improve mode applies professional tone enhancement', () async {
    await personalStyleRepo.updateFormality(FormalityStyle.formal);

    final result = await repository.correct(
      text: 'tell me the result asap in order to finish',
      selectedLanguage: AppLanguage.english,
      mode: CorrectionMode.improve,
    );

    expect(result.issues.isNotEmpty, isTrue);
    expect(result.issues.any((i) => i.category == IssueCategory.style || i.category == IssueCategory.clarity), isTrue);
  });

  test('Owner acceptance fixtures pass with high precision', () async {
    final fixtureFile = File('test/fixtures/owner_acceptance.json');
    if (!fixtureFile.existsSync()) return;

    final cases = jsonDecode(fixtureFile.readAsStringSync()) as List<dynamic>;

    for (final c in cases) {
      final input = c['input'] as String;
      final expected = c['expected'] as String;
      final category = c['category'] as String;

      final result = await repository.correct(
        text: input,
        selectedLanguage: AppLanguage.english,
      );

      if (category == 'clean_no_edit' || category == 'protected_spans') {
        expect(result.correctedText, equals(expected),
            reason: 'Clean/protected input should not be modified: $input');
      } else {
        expect(result.correctedText, equals(expected),
            reason: 'Failed correction for case: $input');
      }
    }
  });
}
