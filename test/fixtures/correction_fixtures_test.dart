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
  TestWidgetsFlutterBinding.ensureInitialized();

  late CorrectionRepository repository;
  late PersonalStyleRepository personalStyleRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'multilingual_model_pack_installed': true});
    final prefs = await SharedPreferences.getInstance();

    final harperEngine = HarperEngine();
    final multilingualEngine = MultilingualEngine();
    const languageDetector = LanguageDetector();
    final typoEngine = TypoCandidateEngine();

    final customDictRepo = CustomDictionaryRepository(prefs: prefs);
    final modelPackRepo = ModelPackRepository(prefs: prefs);
    personalStyleRepo = PersonalStyleRepository(prefs);

    repository = CorrectionRepository(
      harperEngine: harperEngine,
      multilingualEngine: multilingualEngine,
      languageDetector: languageDetector,
      customDictionaryRepo: customDictRepo,
      modelPackRepo: modelPackRepo,
      personalStyleRepo: personalStyleRepo,
      typoCandidateEngine: typoEngine,
    );
  });

  group('Correction Fixtures Suite', () {
    final fixtureFiles = [
      'character_errors.json',
      'word_boundaries.json',
      'contextual_spelling.json',
      'grammar_agreement.json',
      'protected_spans.json',
      'informal_writing.json',
      'multilingual_context.json',
    ];

    for (final filename in fixtureFiles) {
      test('Fixture test: $filename', () async {
        final file = File('test/fixtures/corrections/$filename');
        if (!file.existsSync()) return;

        final rawJson = file.readAsStringSync();
        final testCases = jsonDecode(rawJson) as List<dynamic>;

        for (final tc in testCases) {
          final map = tc as Map<String, dynamic>;
          final input = map['input'] as String;
          final langCode = map['language'] as String;
          final requiredEdits = map['required_edits'] as List<dynamic>? ?? [];
          final forbiddenEdits = map['forbidden_edits'] as List<dynamic>? ?? [];

          final appLang = AppLanguage.fromCode(langCode);

          final result = await repository.correct(
            text: input,
            selectedLanguage: appLang,
          );

          // 1. Verify required edits are fixed in correctedText or detected as issues
          for (final req in requiredEdits) {
            final reqMap = req as Map<String, dynamic>;
            final original = reqMap['original'] as String;
            final replacement = reqMap['replacement'] as String;

            final hasIssue = result.issues.any((i) =>
                i.original.toLowerCase().contains(original.toLowerCase()) ||
                i.suggestions.any((s) => s.toLowerCase().contains(replacement.toLowerCase())));

            final hasCorrected = result.correctedText.contains(replacement);

            expect(
              hasIssue || hasCorrected,
              isTrue,
              reason: 'Failed in $filename (${map["id"]}): expected edit "$original" -> "$replacement" in "$input"',
            );
          }

          // 2. Verify forbidden edits are NOT mutated
          for (final forbidden in forbiddenEdits) {
            final forbiddenStr = forbidden as String;
            expect(
              result.correctedText.contains(forbiddenStr),
              isTrue,
              reason: 'Failed in $filename (${map["id"]}): forbidden token "$forbiddenStr" was modified in "$input"',
            );
          }
        }
      });
    }
  });
}
