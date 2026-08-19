import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/data/repositories/correction_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/model_pack_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';
import 'package:grammarfix/features/correction/domain/services/typo_candidate_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Multilingual Quality Gate (GEC Fixtures)', () {
    late CorrectionRepository repository;
    late ModelPackRepository modelPackRepo;
    late PersonalStyleRepository personalStyleRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'multilingual_model_pack_installed': true});
      final prefs = await SharedPreferences.getInstance();

      modelPackRepo = ModelPackRepository(prefs: prefs);
      personalStyleRepo = PersonalStyleRepository(prefs);
      repository = CorrectionRepository(
        harperEngine: HarperEngine(),
        multilingualEngine: MultilingualEngine(),
        languageDetector: const LanguageDetector(),
        customDictionaryRepo: CustomDictionaryRepository(prefs: prefs),
        modelPackRepo: modelPackRepo,
        personalStyleRepo: personalStyleRepo,
        typoCandidateEngine: TypoCandidateEngine(),
      );
    });

    Future<void> runFixtureTest(String langCode, AppLanguage language) async {
      final file = File('test/fixtures/gec/$langCode.json');
      expect(file.existsSync(), isTrue, reason: 'Fixture file for $langCode must exist');

      final content = file.readAsStringSync();
      final list = jsonDecode(content) as List<dynamic>;

      for (final item in list) {
        final fixture = item as Map<String, dynamic>;
        final id = fixture['id'] as String;
        final input = fixture['input'] as String;
        final acceptedOutputs = (fixture['acceptedOutputs'] as List<dynamic>).map((s) => s.toString()).toList();

        final result = await repository.correct(
          text: input,
          selectedLanguage: language,
        );

        final corrected = result.correctedText.trim();
        final matchesAnyAccepted = acceptedOutputs.any((acc) => acc.trim() == corrected);

        expect(
          matchesAnyAccepted,
          isTrue,
          reason: 'Fixture $id failed for $langCode.\nInput: "$input"\nGot: "$corrected"\nExpected one of: $acceptedOutputs',
        );
      }
    }

    test('English fixtures pass (en.json)', () async {
      await runFixtureTest('en', AppLanguage.english);
    });

    test('Arabic fixtures pass (ar.json)', () async {
      await runFixtureTest('ar', AppLanguage.arabic);
    });

    test('French fixtures pass (fr.json)', () async {
      await runFixtureTest('fr', AppLanguage.french);
    });

    test('Spanish fixtures pass (es.json)', () async {
      await runFixtureTest('es', AppLanguage.spanish);
    });

    test('German fixtures pass (de.json)', () async {
      await runFixtureTest('de', AppLanguage.german);
    });

    test('Portuguese fixtures pass (pt.json)', () async {
      await runFixtureTest('pt', AppLanguage.portuguese);
    });

    test('Italian fixtures pass (it.json)', () async {
      await runFixtureTest('it', AppLanguage.italian);
    });
  });
}
