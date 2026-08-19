import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/domain/services/protected_span_detector.dart';

void main() {
  group('ProtectedSpanDetector Tests', () {
    test('detects URLs, emails, usernames, hashtags, and code blocks', () {
      const text = 'Email john@example.com or visit https://mogate.tech and check `var x = 1;` @mogate #Flutter';
      final spans = ProtectedSpanDetector.detect(text);

      expect(spans.any((s) => s.type == 'email' && s.text == 'john@example.com'), isTrue);
      expect(spans.any((s) => s.type == 'url' && s.text.contains('https://mogate.tech')), isTrue);
      expect(spans.any((s) => s.type == 'code' && s.text == '`var x = 1;`'), isTrue);
      expect(spans.any((s) => s.type == 'username' && s.text.contains('@mogate')), isTrue);
      expect(spans.any((s) => s.type == 'hashtag' && s.text.contains('#Flutter')), isTrue);
    });

    test('isEditAllowed blocks edits that overlap protected spans', () {
      const text = 'Contact john@example.com now.';
      final spans = ProtectedSpanDetector.detect(text);
      final emailSpan = spans.firstWhere((s) => s.type == 'email');

      // Edit inside email is blocked
      final allowedInside = ProtectedSpanDetector.isEditAllowed(emailSpan.start + 2, emailSpan.end - 2, spans);
      expect(allowedInside, isFalse);

      // Edit outside email (e.g. "now") is allowed
      final nowIndex = text.indexOf('now');
      final allowedOutside = ProtectedSpanDetector.isEditAllowed(nowIndex, nowIndex + 3, spans);
      expect(allowedOutside, isTrue);
    });
  });
}
