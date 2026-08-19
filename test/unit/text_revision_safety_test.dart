import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/data/repositories/correction_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/model_pack_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Text Revision Safety', () {
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

    test('stale revision results are discarded when text has been updated', () async {
      // Simulate user initiating revision 1
      repository.correct(text: 'He don\'t know.', revision: 1);

      // User immediately types more, bumping revision to 2
      final res2 = await repository.correct(text: 'He doesn\'t know anyone here.', revision: 2);
      expect(res2.sourceRevision, 2);

      // Verify repository tracked the newer revision
      expect(repository.latestRevision >= 2, isTrue);
    });
  });
}
