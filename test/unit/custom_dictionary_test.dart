import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CustomDictionaryRepository', () {
    late CustomDictionaryRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = CustomDictionaryRepository(prefs: prefs);
    });

    test('adds word and retrieves sorted list', () async {
      await repository.addWord('Mogate');
      await repository.addWord('Antigravity');
      final words = repository.getWords();

      expect(words, ['Antigravity', 'Mogate']);
    });

    test('does not add duplicate words case-insensitively', () async {
      await repository.addWord('GrammarFix');
      await repository.addWord('grammarfix');
      final words = repository.getWords();

      expect(words.length, 1);
    });

    test('removes word correctly', () async {
      await repository.addWord('Flutter');
      await repository.addWord('Dart');
      await repository.removeWord('Flutter');

      final words = repository.getWords();
      expect(words, ['Dart']);
    });

    test('clears all custom words', () async {
      await repository.addWord('Word1');
      await repository.addWord('Word2');
      await repository.clear();

      expect(repository.getWords(), isEmpty);
    });
  });
}
