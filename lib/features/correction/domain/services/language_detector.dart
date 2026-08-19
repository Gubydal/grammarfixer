import '../entities/language.dart';

class LanguageDetectionResult {
  const LanguageDetectionResult({
    required this.language,
    required this.confidence,
    this.isConfident = true,
  });

  final AppLanguage language;
  final double confidence;
  final bool isConfident;
}

/// Fast local on-device language identification.
///
/// Keeps all user text 100% on device without any network requests.
class LanguageDetector {
  const LanguageDetector();

  LanguageDetectionResult detect(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const LanguageDetectionResult(
        language: AppLanguage.english,
        confidence: 1.0,
      );
    }

    // 1. Check for Arabic script (high confidence)
    final arabicPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    var arabicChars = 0;
    var latinChars = 0;

    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (arabicPattern.hasMatch(char)) {
        arabicChars++;
      } else if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        latinChars++;
      }
    }

    if (arabicChars > 0 && arabicChars >= latinChars) {
      final confidence = (arabicChars / (arabicChars + latinChars + 1)).clamp(0.6, 1.0);
      return LanguageDetectionResult(
        language: AppLanguage.arabic,
        confidence: confidence,
        isConfident: confidence >= 0.7,
      );
    }

    // 2. Token-based detection for Latin-script languages
    final words = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return const LanguageDetectionResult(
        language: AppLanguage.english,
        confidence: 0.8,
      );
    }

    final scores = <AppLanguage, int>{
      AppLanguage.english: 0,
      AppLanguage.french: 0,
      AppLanguage.spanish: 0,
      AppLanguage.german: 0,
      AppLanguage.portuguese: 0,
      AppLanguage.italian: 0,
    };

    for (final word in words) {
      if (_englishStopwords.contains(word)) scores[AppLanguage.english] = scores[AppLanguage.english]! + 3;
      if (_frenchStopwords.contains(word)) scores[AppLanguage.french] = scores[AppLanguage.french]! + 3;
      if (_spanishStopwords.contains(word)) scores[AppLanguage.spanish] = scores[AppLanguage.spanish]! + 3;
      if (_germanStopwords.contains(word)) scores[AppLanguage.german] = scores[AppLanguage.german]! + 3;
      if (_portugueseStopwords.contains(word)) scores[AppLanguage.portuguese] = scores[AppLanguage.portuguese]! + 3;
      if (_italianStopwords.contains(word)) scores[AppLanguage.italian] = scores[AppLanguage.italian]! + 3;
    }

    // Check language-specific character cues
    if (trimmed.contains(RegExp(r'[äöüßÄÖÜ]'))) scores[AppLanguage.german] = scores[AppLanguage.german]! + 5;
    if (trimmed.contains(RegExp(r'[ñ¿¡]'))) scores[AppLanguage.spanish] = scores[AppLanguage.spanish]! + 5;
    if (trimmed.contains(RegExp(r'[ãõ]'))) scores[AppLanguage.portuguese] = scores[AppLanguage.portuguese]! + 5;
    if (trimmed.contains(RegExp(r'[œæ]'))) scores[AppLanguage.french] = scores[AppLanguage.french]! + 5;

    var bestLang = AppLanguage.english;
    var maxScore = -1;
    var totalScore = 0;

    scores.forEach((lang, score) {
      totalScore += score;
      if (score > maxScore) {
        maxScore = score;
        bestLang = lang;
      }
    });

    if (maxScore == 0) {
      // Default to English if no definitive stop words matched
      return const LanguageDetectionResult(
        language: AppLanguage.english,
        confidence: 0.7,
        isConfident: false,
      );
    }

    final confidence = (maxScore / (totalScore > 0 ? totalScore : 1)).clamp(0.5, 0.98);
    return LanguageDetectionResult(
      language: bestLang,
      confidence: confidence,
      isConfident: confidence >= 0.6 || maxScore >= 6,
    );
  }

  static const _englishStopwords = {
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i',
    'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
    'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
    'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what',
    'is', 'are', 'was', 'were', 'has', 'had', 'been', 'can', 'could', 'should',
  };

  static const _frenchStopwords = {
    'le', 'la', 'les', 'de', 'des', 'du', 'un', 'une', 'et', 'est',
    'en', 'que', 'qui', 'dans', 'pour', 'pas', 'sur', 'ce', 'avec', 'tout',
    'faire', 'son', 'plus', 'par', 'je', 'il', 'ils', 'elle', 'elles', 'nous',
    'vous', 'sont', 'ont', 'mais', 'ou', 'donc', 'or', 'ni', 'car', 'très',
  };

  static const _spanishStopwords = {
    'el', 'la', 'los', 'las', 'de', 'del', 'un', 'una', 'unos', 'unas',
    'y', 'es', 'en', 'que', 'por', 'para', 'con', 'no', 'se', 'su',
    'al', 'como', 'más', 'pero', 'sus', 'le', 'ya', 'o', 'fue', 'este',
    'son', 'está', 'están', 'muy', 'todos', 'nosotros', 'ellos', 'ellas',
  };

  static const _germanStopwords = {
    'der', 'die', 'das', 'den', 'dem', 'des', 'ein', 'eine', 'einer', 'eines',
    'einem', 'einen', 'und', 'in', 'zu', 'nicht', 'von', 'sie',
    'ist', 'sich', 'mit', 'dass', 'er', 'es', 'an', 'wie',
    'wir', 'sind', 'war', 'waren', 'haben', 'hat', 'hatte', 'für', 'aber',
  };

  static const _portugueseStopwords = {
    'o', 'a', 'os', 'as', 'de', 'do', 'da', 'dos', 'das', 'em',
    'no', 'na', 'nos', 'nas', 'um', 'uma', 'uns', 'umas', 'por', 'para',
    'com', 'não', 'que', 'se', 'seu', 'sua', 'seus', 'suas', 'como', 'mais',
    'mas', 'foi', 'ao', 'aos', 'à', 'às', 'muito', 'muita', 'está', 'são',
  };

  static const _italianStopwords = {
    'il', 'lo', 'la', 'i', 'gli', 'le', 'l', 'un', 'uno', 'una',
    'di', 'del', 'dello', 'della', 'dei', 'degli', 'delle', 'a', 'al', 'allo',
    'alla', 'ai', 'agli', 'alle', 'da', 'dal', 'in', 'con', 'su', 'per',
    'tra', 'fra', 'è', 'sono', 'non', 'che', 'si', 'ha', 'hanno', 'molto',
  };
}
