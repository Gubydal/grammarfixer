import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';

void main() {
  group('No Translation Guardrails', () {
    final engine = MultilingualEngine();
    const detector = LanguageDetector();

    test('Arabic input must remain in Arabic (no translation to English)', () async {
      const input = 'هذه كتاب جميل جدا';
      final result = await engine.correct(text: input, language: AppLanguage.arabic);

      // Verify language of output is still Arabic
      final detected = detector.detect(result.correctedText);
      expect(detected.language, AppLanguage.arabic);
      expect(result.correctedText.contains('This is'), isFalse);
      expect(result.correctedText.contains('book'), isFalse);
    });

    test('French input must remain in French', () async {
      const input = 'Les chat sont très mignon.';
      final result = await engine.correct(text: input, language: AppLanguage.french);

      final detected = detector.detect(result.correctedText);
      expect(detected.language, AppLanguage.french);
      expect(result.correctedText.contains('The cats are'), isFalse);
    });

    test('Spanish input must remain in Spanish', () async {
      const input = 'Los niño juegan en el parque.';
      final result = await engine.correct(text: input, language: AppLanguage.spanish);

      final detected = detector.detect(result.correctedText);
      expect(detected.language, AppLanguage.spanish);
      expect(result.correctedText.contains('The children play'), isFalse);
    });
  });
}
