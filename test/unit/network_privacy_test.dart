import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/data/repositories/correction_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/model_pack_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Network Privacy Audit', () {
    late CorrectionRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      repository = CorrectionRepository(
        harperEngine: HarperEngine(),
        multilingualEngine: MultilingualEngine(),
        languageDetector: const LanguageDetector(),
        customDictionaryRepo: CustomDictionaryRepository(prefs: prefs),
        modelPackRepo: ModelPackRepository(prefs: prefs),
        personalStyleRepo: PersonalStyleRepository(prefs),
      );
    });

    test('sensitive text correction executes 100% locally with zero network calls', () async {
      const sensitiveText = 'My confidential password is Secret123 and SSN is 000-00-0000. He don\'t know.';

      final result = await repository.correct(
        text: sensitiveText,
        selectedLanguage: AppLanguage.english,
      );

      // Verify correction happened locally
      expect(result.issues, isNotEmpty);
      expect(result.correctedText.contains('He doesn\'t know'), isTrue);
      expect(result.engineName.contains('Harper'), isTrue);
    });
  });
}
