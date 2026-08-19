import '../entities/language.dart';

/// Represents a distinct rewritten alternative for a piece of text.
class RewriteOption {
  const RewriteOption({
    required this.toneId,
    required this.toneLabel,
    required this.icon,
    required this.rewrittenText,
    required this.description,
  });

  final String toneId;
  final String toneLabel;
  final String icon;
  final String rewrittenText;
  final String description;
}

/// On-device multi-tone sentence and paragraph rewrite engine.
/// Produces 3 structured alternative options:
/// 1. Professional (👔)
/// 2. Friendly / Casual (😊)
/// 3. Concise / Direct (⚡)
class SentenceRewriteEngine {
  const SentenceRewriteEngine();

  /// Generates multi-tone rewrite options for [sourceText].
  List<RewriteOption> generateRewrites({
    required String sourceText,
    required String baseCorrectedText,
    EnglishDialect dialect = EnglishDialect.american,
  }) {
    final text = baseCorrectedText.trim().isNotEmpty ? baseCorrectedText.trim() : sourceText.trim();
    if (text.isEmpty) return const [];

    final professional = _rewriteProfessional(text, dialect);
    final friendly = _rewriteFriendly(text, dialect);
    final concise = _rewriteConcise(text, dialect);

    return [
      RewriteOption(
        toneId: 'professional',
        toneLabel: 'Professional',
        icon: '👔',
        rewrittenText: professional,
        description: 'Polished, formal phrasing for business & work',
      ),
      RewriteOption(
        toneId: 'friendly',
        toneLabel: 'Friendly',
        icon: '😊',
        rewrittenText: friendly,
        description: 'Warm, approachable, and conversational',
      ),
      RewriteOption(
        toneId: 'concise',
        toneLabel: 'Concise',
        icon: '⚡',
        rewrittenText: concise,
        description: 'Direct and impactful, removes filler words',
      ),
    ];
  }

  String _rewriteProfessional(String input, EnglishDialect dialect) {
    var text = input;

    // Greeting transformations
    text = text.replaceAll(RegExp(r'^(?:[Hh]i|[Hh]ello|[Hh]ey),?\s+can we be friends\??', caseSensitive: false), 'I would appreciate the opportunity to connect with you.');
    text = text.replaceAll(RegExp(r'^(?:[Hh]ey|[Hh]i|[Yy]o),?\s+', caseSensitive: false), 'Dear colleague, ');
    text = text.replaceAll(RegExp(r'\bcan we be friends\??', caseSensitive: false), 'would you be open to connecting?');

    // Vocabulary elevation & formal phrasing
    const formalReplacements = {
      'tell me': 'please inform me',
      'let me know': 'please keep me updated',
      'asap': 'at your earliest convenience',
      'a lot of': 'a substantial amount of',
      'very good': 'exceptional',
      'very bad': 'unfavorable',
      'get in touch': 'establish contact',
      'need your help': 'require your assistance',
      'sorry for the delay': 'thank you for your patience regarding the delay',
      'in order to': 'to',
      'wanna': 'would like to',
      'gonna': 'intend to',
      'gotta': 'must',
      'kinda': 'somewhat',
      'sorta': 'somewhat',
      'no problem': 'you are most welcome',
      'thanks': 'thank you',
      'bye': 'sincerely',
    };

    for (final entry in formalReplacements.entries) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false), entry.value);
    }

    // Expand contractions for formal tone
    const contractionExpansions = {
      "don't": "do not",
      "can't": "cannot",
      "won't": "will not",
      "didn't": "did not",
      "isn't": "is not",
      "aren't": "are not",
      "wasn't": "was not",
      "weren't": "were not",
      "hasn't": "has not",
      "haven't": "have not",
      "hadn't": "had not",
      "it's": "it is",
      "I'm": "I am",
      "you're": "you are",
      "they're": "they are",
      "we're": "we are",
      "I'll": "I will",
      "you'll": "you will",
      "we'll": "we will",
    };

    for (final entry in contractionExpansions.entries) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false), entry.value);
    }

    return _ensurePunctuation(text);
  }

  String _rewriteFriendly(String input, EnglishDialect dialect) {
    var text = input;

    // Greeting transformations
    text = text.replaceAll(RegExp(r'^(?:[Dd]ear [Ss]ir|[Dd]ear [Mm]adam|[Tt]o whom it may concern),?\s*', caseSensitive: false), 'Hi there! ');
    text = text.replaceAll(RegExp(r'^(?:[Hh]i|[Hh]ello),?\s+can we be friends\??', caseSensitive: false), 'Hey, I\'d love to connect and be friends!');

    const friendlyReplacements = {
      'I am writing to inquire': 'I was just wondering',
      'at your earliest convenience': 'whenever you get a moment',
      'furthermore': 'also',
      'nevertheless': 'anyway',
      'subsequently': 'after that',
      'commence': 'kick off',
      'terminate': 'wrap up',
      'utilize': 'use',
      'require assistance': 'could use a hand',
      'please inform me': 'let me know',
    };

    for (final entry in friendlyReplacements.entries) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false), entry.value);
    }

    // Use contractions for friendly tone
    const friendlyContractions = {
      "do not": "don't",
      "cannot": "can't",
      "will not": "won't",
      "did not": "didn't",
      "is not": "isn't",
      "are not": "aren't",
      "it is": "it's",
      "I am": "I'm",
      "you are": "you're",
      "they are": "they're",
      "we are": "we're",
    };

    for (final entry in friendlyContractions.entries) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false), entry.value);
    }

    return _ensurePunctuation(text);
  }

  String _rewriteConcise(String input, EnglishDialect dialect) {
    var text = input;

    // Greeting transformations
    text = text.replaceAll(RegExp(r'^(?:[Hh]i|[Hh]ello|[Hh]ey|[Dd]ear [a-zA-Z]+),?\s+can we be friends\??', caseSensitive: false), 'Let\'s connect.');

    const conciseReplacements = {
      'in order to': 'to',
      'at this point in time': 'now',
      'at the present time': 'currently',
      'due to the fact that': 'because',
      'for the purpose of': 'for',
      'in the event that': 'if',
      'with regard to': 'regarding',
      'is able to': 'can',
      'has the capability to': 'can',
      'a majority of': 'most',
      'a number of': 'several',
      'at all times': 'always',
      'in spite of the fact that': 'although',
      'until such time as': 'until',
      'prior to': 'before',
      'subsequent to': 'after',
      'please let me know': 'let me know',
      'at your earliest convenience': 'soon',
      'as soon as possible': 'asap',
      'take into consideration': 'consider',
    };

    for (final entry in conciseReplacements.entries) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false), entry.value);
    }

    return _ensurePunctuation(text);
  }

  String _ensurePunctuation(String text) {
    var trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!RegExp(r'[\.\!\?]$').hasMatch(trimmed)) {
      if (RegExp(r'^(can|could|would|will|is|are|do|does|did|how|what|why|where|when|who)\b', caseSensitive: false).hasMatch(trimmed)) {
        trimmed += '?';
      } else {
        trimmed += '.';
      }
    }
    // Capitalize first letter
    if (trimmed.isNotEmpty && trimmed[0] == trimmed[0].toLowerCase()) {
      trimmed = trimmed[0].toUpperCase() + trimmed.substring(1);
    }
    return trimmed;
  }
}
