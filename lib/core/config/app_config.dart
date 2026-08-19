import 'app_legal_urls.dart';

/// Central per-app configuration.
///
/// Values are supplied at build time through `--dart-define-from-file`
/// (see `dart_defines/example.json`). Public mobile SDK keys are safe to ship
/// in the client; secrets such as Supabase service-role keys must never go here.
class AppConfig {
  const AppConfig._();

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'GrammarFix',
  );

  static const String appSlug = String.fromEnvironment(
    'APP_SLUG',
    defaultValue: 'grammar-fix',
  );

  static const String applicationId = String.fromEnvironment(
    'APPLICATION_ID',
    defaultValue: 'com.mogate.grammarfix',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  static const String supabaseSchema = String.fromEnvironment(
    'SUPABASE_SCHEMA',
    defaultValue: 'app_grammar_fix',
  );

  static const String deepLinkScheme = String.fromEnvironment(
    'DEEP_LINK_SCHEME',
    defaultValue: 'com.mogate.grammarfix',
  );

  static const String deepLinkHost = 'callback';

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: '',
  );

  static const String admobAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );

  static const String admobBannerAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );

  static const String admobInterstitialAdUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );

  static const String admobAppOpenAdUnitId = String.fromEnvironment(
    'ADMOB_APP_OPEN_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/9257395921',
  );

  /// Optional generic API base URL for apps that ship a backend/Worker.
  /// Leave empty for normal apps that only use Supabase directly.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Test/launch override that treats the app as Pro without RevenueCat.
  static const bool forcePro = bool.fromEnvironment(
    'FORCE_PRO',
    defaultValue: false,
  );

  // -------------------------------------------------------------------------
  // Legal URLs
  //
  // By default every app gets the Mogate subdomain pattern derived from its
  // slug. An explicit per-app override in dart_defines wins when provided.
  // -------------------------------------------------------------------------

  static const String _privacyUrlOverride = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: '',
  );

  static const String _termsUrlOverride = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: '',
  );

  static const String _deleteAccountUrlOverride = String.fromEnvironment(
    'DELETE_ACCOUNT_URL',
    defaultValue: '',
  );

  static const AppLegalUrls legalUrls = AppLegalUrls(
    slug: appSlug,
    privacyOverride: _privacyUrlOverride,
    termsOverride: _termsUrlOverride,
    deleteAccountOverride: _deleteAccountUrlOverride,
  );

  static String get privacyPolicyUrl => legalUrls.privacyPolicyUrl;

  static String get termsUrl => legalUrls.termsUrl;

  static String get accountDeletionUrl => legalUrls.accountDeletionUrl;

  static Uri get deepLinkUri => Uri(
    scheme: deepLinkScheme,
    host: deepLinkHost,
  );
}
