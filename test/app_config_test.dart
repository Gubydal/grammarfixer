import 'package:grammarfix/core/config/app_legal_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLegalUrls', () {
    test('derives Mogate subdomain URLs from the slug', () {
      const urls = AppLegalUrls(slug: 'myapp');

      expect(urls.privacyPolicyUrl, 'https://myapp.mogate.tech/privacy');
      expect(urls.termsUrl, 'https://myapp.mogate.tech/terms');
      expect(urls.accountDeletionUrl, 'https://myapp.mogate.tech/delete-account');
    });

    test('explicit overrides win', () {
      const urls = AppLegalUrls(
        slug: 'myapp',
        privacyOverride: 'https://example.com/privacy',
        termsOverride: 'https://example.com/terms',
        deleteAccountOverride: 'https://example.com/delete',
      );

      expect(urls.privacyPolicyUrl, 'https://example.com/privacy');
      expect(urls.termsUrl, 'https://example.com/terms');
      expect(urls.accountDeletionUrl, 'https://example.com/delete');
    });
  });
}
