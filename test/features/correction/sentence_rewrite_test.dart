import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/sentence_rewrite_engine.dart';

void main() {
  late SentenceRewriteEngine engine;

  setUp(() {
    engine = const SentenceRewriteEngine();
  });

  test('SentenceRewriteEngine generates 3 distinct options (Professional, Friendly, Concise)', () {
    final rewrites = engine.generateRewrites(
      sourceText: 'hi can we be friend',
      baseCorrectedText: 'Hi, can we be friends?',
      dialect: EnglishDialect.american,
    );

    expect(rewrites.length, equals(3));
    expect(rewrites[0].toneId, equals('professional'));
    expect(rewrites[1].toneId, equals('friendly'));
    expect(rewrites[2].toneId, equals('concise'));

    // Professional option
    expect(rewrites[0].rewrittenText.toLowerCase().contains('connect'), isTrue);

    // Friendly option
    expect(rewrites[1].rewrittenText.toLowerCase().contains('friends'), isTrue);

    // Concise option
    expect(rewrites[2].rewrittenText.toLowerCase().contains('connect'), isTrue);
  });

  test('SentenceRewriteEngine transforms wordy and informal business requests', () {
    final rewrites = engine.generateRewrites(
      sourceText: 'tell me the result asap in order to finish the work',
      baseCorrectedText: 'Tell me the result asap in order to finish the work.',
      dialect: EnglishDialect.american,
    );

    expect(rewrites.length, equals(3));

    // Professional replaces 'tell me' and 'asap'
    final prof = rewrites[0].rewrittenText.toLowerCase();
    expect(prof.contains('earliest convenience') || prof.contains('inform me'), isTrue);

    // Concise removes 'in order to' and 'asap'
    final concise = rewrites[2].rewrittenText.toLowerCase();
    expect(concise.contains('in order to'), isFalse);
    expect(concise.contains('to finish'), isTrue);
  });
}
