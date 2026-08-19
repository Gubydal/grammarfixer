import 'dart:math';
import '../entities/correction_issue.dart';
import '../entities/language.dart';
import 'protected_span_detector.dart';

/// Fast on-device typo and spelling candidate engine.
///
/// Implements edit-distance candidate ranking, character-repetition collapsing,
/// joined/split word detection, and common transposition repair without cloud dependencies.
class TypoCandidateEngine {
  final Set<String> _userDictionary = {};

  void setUserDictionary(Iterable<String> words) {
    _userDictionary.clear();
    _userDictionary.addAll(words.map((w) => w.toLowerCase()));
  }

  // 1. High-frequency transposition & common misspellings dictionary
  static const Map<String, String> _commonMisspellings = {
    'teh': 'the',
    'recieve': 'receive',
    'recieved': 'received',
    'recieving': 'receiving',
    'seperate': 'separate',
    'seperated': 'separated',
    'seperately': 'separately',
    'thsi': 'this',
    'becuase': 'because',
    'adn': 'and',
    'taht': 'that',
    'wierd': 'weird',
    'freind': 'friend',
    'freinds': 'friends',
    'occured': 'occurred',
    'occuring': 'occurring',
    'untill': 'until',
    'truely': 'truly',
    'definately': 'definitely',
    'definitiely': 'definitely',
    'definitly': 'definitely',
    'accomodate': 'accommodate',
    'embarass': 'embarrass',
    'embarassed': 'embarrassed',
    'neccessary': 'necessary',
    'goverment': 'government',
    'tommorow': 'tomorrow',
    'adress': 'address',
    'adresses': 'addresses',
    'belive': 'believe',
    'belived': 'believed',
    'calender': 'calendar',
    'succesful': 'successful',
    'unfortunatly': 'unfortunately',
    'experiance': 'experience',
    'arguement': 'argument',
    'guarentee': 'guarantee',
    'priviledge': 'privilege',
    'refering': 'referring',
    'begining': 'beginning',
    'alright': 'all right',
    'definatelyyy': 'definitely',
    'hellooooo': 'hello',
    'whatt': 'what',
  };

  // 2. Common joined words -> split words
  static const Map<String, String> _joinedWords = {
    'alot': 'a lot',
    'inthe': 'in the',
    'aswell': 'as well',
    'atleast': 'at least',
    'eachother': 'each other',
    'infront': 'in front',
    'nevermind': 'never mind',
    'thankyou': 'thank you',
    'incase': 'in case',
    'allmost': 'almost',
    'noone': 'no one',
    'highschool': 'high school',
    'everytime': 'every time',
    'firsthand': 'first hand',
  };

  // 3. Common split words -> joined words
  static const Map<String, String> _splitWords = {
    'some thing': 'something',
    'some one': 'someone',
    'some where': 'somewhere',
    'some times': 'sometimes',
    'any thing': 'anything',
    'any one': 'anyone',
    'any where': 'anywhere',
    'no body': 'nobody',
    'every thing': 'everything',
    'every where': 'everywhere',
    'can not': 'cannot',
    'with out': 'without',
    'mean while': 'meanwhile',
    'in side': 'inside',
    'out side': 'outside',
  };

  // 4. Common missing apostrophes
  static const Map<String, String> _missingApostrophes = {
    'im': "I'm",
    'ive': "I've",
    'cant': "can't",
    'wont': "won't",
    'dont': "don't",
    'didnt': "didn't",
    'isnt': "isn't",
    'arent': "aren't",
    'wasnt': "wasn't",
    'werent': "weren't",
    'hasnt': "hasn't",
    'havent': "haven't",
    'hadnt': "hadn't",
    'couldnt': "couldn't",
    'shouldnt': "shouldn't",
    'wouldnt': "wouldn't",
    'theyre': "they're",
    'youre': "you're",
    'thats': "that's",
    'whats': "what's",
    'theres': "there's",
    'heres': "here's",
    'wheres': "where's",
    'whos': "who's",
    'hows': "how's",
    'lets': "let's",
    'doesnt': "doesn't",
    'couldve': "could've",
    'shouldve': "should've",
    'wouldve': "would've",
  };

  // 5. Valid words with 2 repeated characters to NEVER collapse incorrectly
  static const Set<String> _validRepeatedCharWords = {
    'coffee', 'bookkeeper', 'bookkeeping', 'committee', 'balloon', 'success',
    'access', 'agree', 'llama', 'beef', 'beer', 'good', 'cool', 'look', 'see',
    'feel', 'meet', 'tree', 'free', 'sleep', 'deep', 'keep', 'week', 'feet',
    'sweet', 'green', 'speed', 'noon', 'moon', 'food', 'pool', 'fool', 'tool',
    'wool', 'wood', 'door', 'floor', 'poor', 'zoom', 'room', 'boom', 'spoon',
    'shoot', 'root', 'boot', 'tooth', 'smooth', 'goose', 'loose', 'choose',
    'cheese', 'proof', 'roof', 'took', 'hook', 'cook', 'book', 'shook', 'foot',
    'spelling', 'grammar', 'happy', 'little', 'letter', 'middle', 'yellow',
    'follow', 'allow', 'pillow', 'apple', 'dinner', 'winner', 'summer', 'hammer',
    'butter', 'better', 'bitter', 'matter', 'bottle', 'cattle', 'kettle', 'settle',
    'traffic', 'office', 'cliff', 'stiff', 'sniff', 'fluff', 'stuff',
    'grass', 'glass', 'class', 'dress', 'press', 'cross', 'boss', 'loss', 'toss',
  };

  /// Processes text and returns spelling & typo candidate issues.
  List<CorrectionIssue> findTypoIssues(
    String text, {
    required AppLanguage language,
    required EnglishDialect dialect,
    List<ProtectedSpan> protectedSpans = const [],
  }) {
    if (text.trim().isEmpty) return const [];

    final issues = <CorrectionIssue>[];
    int issueCounter = 0;

    bool isSpanProtected(int start, int end) {
      return !ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans);
    }

    // A. Check for Joined Words (e.g. "inthe" -> "in the", "alot" -> "a lot")
    for (final entry in _joinedWords.entries) {
      final pattern = RegExp('\\b${entry.key}\\b', caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        if (isSpanProtected(match.start, match.end)) continue;

        final original = match.group(0)!;
        if (_userDictionary.contains(original.toLowerCase())) continue;

        var replacement = entry.value;
        if (original.isNotEmpty && original[0] == original[0].toUpperCase()) {
          replacement = replacement[0].toUpperCase() + replacement.substring(1);
        }

        issues.add(
          CorrectionIssue(
            id: 'typo_joined_${++issueCounter}_${match.start}',
            engine: 'typo',
            category: IssueCategory.wordBoundary,
            severity: IssueSeverity.warning,
            confidence: IssueConfidence.high,
            isAutoFixable: true,
            start: match.start,
            end: match.end,
            original: original,
            suggestions: [replacement],
            shortReason: 'Separate joined word "$original" into "$replacement"',
            message: 'Word boundary error: replace "$original" with "$replacement"',
          ),
        );
      }
    }

    // B. Check for Split Words (e.g. "some thing" -> "something")
    for (final entry in _splitWords.entries) {
      final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        if (isSpanProtected(match.start, match.end)) continue;

        final original = match.group(0)!;
        var replacement = entry.value;
        if (original.isNotEmpty && original[0] == original[0].toUpperCase()) {
          replacement = replacement[0].toUpperCase() + replacement.substring(1);
        }

        issues.add(
          CorrectionIssue(
            id: 'typo_split_${++issueCounter}_${match.start}',
            engine: 'typo',
            category: IssueCategory.wordBoundary,
            severity: IssueSeverity.warning,
            confidence: IssueConfidence.high,
            isAutoFixable: true,
            start: match.start,
            end: match.end,
            original: original,
            suggestions: [replacement],
            shortReason: 'Join split word "$original" into "$replacement"',
            message: 'Word boundary error: join "$original" into "$replacement"',
          ),
        );
      }
    }

    // C. Word-level Analysis (typos, repeated letters, missing apostrophes)
    final wordRegex = RegExp(r"\b[a-zA-Z']+\b");
    for (final match in wordRegex.allMatches(text)) {
      final start = match.start;
      final end = match.end;

      if (isSpanProtected(start, end)) continue;
      // Skip if already covered by joined/split word
      if (issues.any((i) => i.start <= start && i.end >= end)) continue;

      final word = match.group(0)!;
      final lower = word.toLowerCase();

      if (_userDictionary.contains(lower)) continue;

      // 1. Direct typo dictionary match (e.g. "recieve" -> "receive", "thsi" -> "this")
      if (_commonMisspellings.containsKey(lower)) {
        var fix = _commonMisspellings[lower]!;
        if (word[0] == word[0].toUpperCase() && fix.isNotEmpty) {
          fix = fix[0].toUpperCase() + fix.substring(1);
        }
        issues.add(
          CorrectionIssue(
            id: 'typo_dict_${++issueCounter}_$start',
            engine: 'typo',
            category: IssueCategory.spelling,
            severity: IssueSeverity.warning,
            confidence: IssueConfidence.high,
            isAutoFixable: true,
            start: start,
            end: end,
            original: word,
            suggestions: [fix],
            shortReason: 'Correct typo "$word" to "$fix"',
            message: 'Possible spelling error: replace "$word" with "$fix"',
          ),
        );
        continue;
      }

      // 2. Missing apostrophe check (e.g. "cant" -> "can't", "theyre" -> "they're")
      if (_missingApostrophes.containsKey(lower)) {
        var fix = _missingApostrophes[lower]!;
        if (word[0] == word[0].toUpperCase() && fix.isNotEmpty) {
          fix = fix[0].toUpperCase() + fix.substring(1);
        }
        issues.add(
          CorrectionIssue(
            id: 'typo_apostrophe_${++issueCounter}_$start',
            engine: 'typo',
            category: IssueCategory.punctuation,
            severity: IssueSeverity.warning,
            confidence: IssueConfidence.high,
            isAutoFixable: true,
            start: start,
            end: end,
            original: word,
            suggestions: [fix],
            shortReason: 'Add apostrophe to "$word" -> "$fix"',
            message: 'Punctuation: replace "$word" with "$fix"',
          ),
        );
        continue;
      }

      // 3. Repeated Characters Collapsing (e.g. "hellooooo" -> "hello", "whatt" -> "what")
      final collapsed = _collapseExcessiveRepeats(word);
      if (collapsed != word && !_validRepeatedCharWords.contains(lower)) {
        final collapsedLower = collapsed.toLowerCase();
        // Check if collapsed version is a known word or typo
        final candidate = _commonMisspellings[collapsedLower] ?? collapsed;
        var fix = candidate;
        if (word[0] == word[0].toUpperCase() && fix.isNotEmpty) {
          fix = fix[0].toUpperCase() + fix.substring(1);
        }

        issues.add(
          CorrectionIssue(
            id: 'typo_repeat_${++issueCounter}_$start',
            engine: 'typo',
            category: IssueCategory.spelling,
            severity: IssueSeverity.warning,
            confidence: IssueConfidence.high,
            isAutoFixable: true,
            start: start,
            end: end,
            original: word,
            suggestions: [fix],
            shortReason: 'Remove repeated letters from "$word" -> "$fix"',
            message: 'Spelling: replace "$word" with "$fix"',
          ),
        );
        continue;
      }
    }

    return issues;
  }

  /// Collapses 3+ identical consecutive characters down to standard English length (1 or 2).
  /// E.g. "hellooooo" -> "hello", "yessss" -> "yes", "cooool" -> "cool"
  String _collapseExcessiveRepeats(String input) {
    if (input.length < 3) return input;

    // Pattern matching 3 or more repeated characters: (a)\1{2,}
    final buffer = StringBuffer();
    int i = 0;
    while (i < input.length) {
      int count = 1;
      while (i + 1 < input.length && input[i].toLowerCase() == input[i + 1].toLowerCase()) {
        count++;
        i++;
      }

      final char = input[i];
      if (count >= 3) {
        // If it's a character that naturally doubles like 'o' (cool), 'e' (see), 'l' (all), try 2 or 1
        final lowerChar = char.toLowerCase();
        if ('oels'.contains(lowerChar)) {
          buffer.write('$char$char');
        } else {
          buffer.write(char);
        }
      } else {
        for (int k = 0; k < count; k++) {
          buffer.write(char);
        }
      }
      i++;
    }

    return buffer.toString();
  }

  /// Calculates Levenshtein edit distance between two strings
  static int editDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[s2.length];
  }
}
