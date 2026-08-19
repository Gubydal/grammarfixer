import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';

void main() {
  group('LanguageDetector', () {
    const detector = LanguageDetector();

    test('detects Arabic text with high confidence', () {
      final res = detector.detect('هذا كتاب رائع ومفيد جداً');
      expect(res.language, AppLanguage.arabic);
      expect(res.isConfident, isTrue);
    });

    test('detects French text', () {
      final res = detector.detect('Bonjour, nous allons faire une réunion avec toute l\'équipe.');
      expect(res.language, AppLanguage.french);
    });

    test('detects Spanish text', () {
      final res = detector.detect('Hola, todos los niños juegan en el parque con sus amigos.');
      expect(res.language, AppLanguage.spanish);
    });

    test('detects German text', () {
      final res = detector.detect('Guten Tag, das ist ein schönes Haus und wir sind glücklich.');
      expect(res.language, AppLanguage.german);
    });

    test('detects Portuguese text', () {
      final res = detector.detect('Olá, os meninos estão muito felizes com a nova casa.');
      expect(res.language, AppLanguage.portuguese);
    });

    test('detects Italian text', () {
      final res = detector.detect('Ciao, i gatti giocano nel salone della casa con un amico.');
      expect(res.language, AppLanguage.italian);
    });

    test('detects English text', () {
      final res = detector.detect('The quick brown fox jumps over the lazy dog in the park.');
      expect(res.language, AppLanguage.english);
    });
  });
}
