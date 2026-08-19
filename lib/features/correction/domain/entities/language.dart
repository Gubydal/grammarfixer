enum EnglishDialect {
  american('American (US)', 'en-US', 0),
  british('British (UK)', 'en-GB', 1),
  canadian('Canadian (CA)', 'en-CA', 2),
  australian('Australian (AU)', 'en-AU', 3);

  const EnglishDialect(this.displayName, this.code, this.nativeCode);
  final String displayName;
  final String code;
  final int nativeCode;

  static EnglishDialect fromString(String val) {
    final lower = val.toLowerCase();
    return EnglishDialect.values.firstWhere(
      (d) => d.name.toLowerCase() == lower || d.code.toLowerCase() == lower,
      orElse: () => EnglishDialect.american,
    );
  }
}

enum AppLanguage {
  auto('Auto detect', 'auto', false, false),
  english('English', 'en', false, false),
  arabic('العربية (Arabic)', 'ar', true, true),
  french('Français (French)', 'fr', false, true),
  spanish('Español (Spanish)', 'es', false, true),
  german('Deutsch (German)', 'de', false, true),
  portuguese('Português (Portuguese)', 'pt', false, true),
  italian('Italiano (Italian)', 'it', false, true);

  const AppLanguage(
    this.displayName,
    this.code,
    this.isRtl,
    this.requiresPack,
  );

  final String displayName;
  final String code;
  final bool isRtl;
  final bool requiresPack;

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code || (code.startsWith('en') && l == AppLanguage.english),
      orElse: () => AppLanguage.english,
    );
  }
}
