import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PersonalStyleRepository Tests', () {
    late PersonalStyleRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('records accepted and rejected style patterns locally', () async {
      final prefs = await SharedPreferences.getInstance();
      repo = PersonalStyleRepository(prefs);

      await repo.recordStyleDecision(
        original: 'color',
        suggestion: 'colour',
        isAccepted: true,
      );

      expect(repo.profile.acceptedStylePatterns.contains('color->colour'), isTrue);
      expect(repo.profile.rejectedStylePatterns.contains('color->colour'), isFalse);

      await repo.recordStyleDecision(
        original: 'color',
        suggestion: 'colour',
        isAccepted: false,
      );

      expect(repo.profile.acceptedStylePatterns.contains('color->colour'), isFalse);
      expect(repo.profile.rejectedStylePatterns.contains('color->colour'), isTrue);
    });

    test('pauses style learning in Private Mode', () async {
      final prefs = await SharedPreferences.getInstance();
      repo = PersonalStyleRepository(prefs);

      await repo.setPrivateMode(true);
      expect(repo.isPrivateMode, isTrue);

      await repo.recordStyleDecision(
        original: 'cannot',
        suggestion: "can't",
        isAccepted: true,
      );

      expect(repo.profile.acceptedStylePatterns.isEmpty, isTrue);
    });

    test('resets personal style to defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      repo = PersonalStyleRepository(prefs);

      await repo.updateDialect(EnglishDialect.british);
      await repo.recordStyleDecision(original: 'a', suggestion: 'b', isAccepted: true);

      expect(repo.profile.dialect, EnglishDialect.british);
      expect(repo.profile.acceptedStylePatterns.isNotEmpty, isTrue);

      await repo.resetProfile();

      expect(repo.profile.dialect, EnglishDialect.american);
      expect(repo.profile.acceptedStylePatterns.isEmpty, isTrue);
    });
  });
}
