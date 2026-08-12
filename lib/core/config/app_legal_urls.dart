/// Derives the app's legal URLs from its slug with optional per-app
/// overrides. Kept as a pure class so the derivation is unit-testable.
class AppLegalUrls {
  const AppLegalUrls({
    required this.slug,
    this.privacyOverride = '',
    this.termsOverride = '',
    this.deleteAccountOverride = '',
  });

  final String slug;
  final String privacyOverride;
  final String termsOverride;
  final String deleteAccountOverride;

  String get privacyPolicyUrl =>
      privacyOverride.isNotEmpty
          ? privacyOverride
          : 'https://$slug.mogate.tech/privacy';

  String get termsUrl =>
      termsOverride.isNotEmpty
          ? termsOverride
          : 'https://$slug.mogate.tech/terms';

  String get accountDeletionUrl =>
      deleteAccountOverride.isNotEmpty
          ? deleteAccountOverride
          : 'https://$slug.mogate.tech/delete-account';
}
