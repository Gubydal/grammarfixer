import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

import '../entities/correction_issue.dart';
import '../entities/correction_result.dart';
import '../entities/language.dart';
import 'protected_span_detector.dart';

typedef _HarperCreateC = ffi.Pointer<ffi.Void> Function(ffi.Int32 dialect);
typedef _HarperCreateDart = ffi.Pointer<ffi.Void> Function(int dialect);

typedef _HarperDestroyC = ffi.Void Function(ffi.Pointer<ffi.Void> ctx);
typedef _HarperDestroyDart = void Function(ffi.Pointer<ffi.Void> ctx);

typedef _HarperAddWordC = ffi.Int32 Function(ffi.Pointer<ffi.Void> ctx, ffi.Pointer<Utf8> word);
typedef _HarperAddWordDart = int Function(ffi.Pointer<ffi.Void> ctx, ffi.Pointer<Utf8> word);

typedef _HarperLintJsonC = ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Void> ctx, ffi.Pointer<Utf8> text);
typedef _HarperLintJsonDart = ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Void> ctx, ffi.Pointer<Utf8> text);

typedef _HarperFreeStringC = ffi.Void Function(ffi.Pointer<Utf8> ptr);
typedef _HarperFreeStringDart = void Function(ffi.Pointer<Utf8> ptr);

/// Harper English Grammar & Spell Checker Engine.
///
/// Communicates with harper-core via Rust C-ABI FFI wrapper on Android devices,
/// with a robust rule-based local grammar and spell checker fallback for tests.
class HarperEngine {
  HarperEngine({
    this.dialect = EnglishDialect.american,
  }) {
    _initNativeLibrary();
  }

  EnglishDialect dialect;
  final Set<String> _userDictionary = {};

  ffi.DynamicLibrary? _dylib;
  ffi.Pointer<ffi.Void>? _nativeContext;

  _HarperCreateDart? _nativeCreate;
  _HarperDestroyDart? _nativeDestroy;
  _HarperAddWordDart? _nativeAddWord;
  _HarperLintJsonDart? _nativeLintJson;
  _HarperFreeStringDart? _nativeFreeString;

  bool get isNativeAvailable => _nativeContext != null && _nativeLintJson != null;

  void _initNativeLibrary() {
    try {
      if (Platform.isAndroid) {
        _dylib = ffi.DynamicLibrary.open('libharper_bridge.so');
      } else if (Platform.isWindows) {
        _dylib = ffi.DynamicLibrary.open('harper_bridge.dll');
      } else if (Platform.isLinux) {
        _dylib = ffi.DynamicLibrary.open('libharper_bridge.so');
      } else if (Platform.isMacOS) {
        _dylib = ffi.DynamicLibrary.open('libharper_bridge.dylib');
      }

      if (_dylib != null) {
        _nativeCreate = _dylib!.lookupFunction<_HarperCreateC, _HarperCreateDart>('harper_create');
        _nativeDestroy = _dylib!.lookupFunction<_HarperDestroyC, _HarperDestroyDart>('harper_destroy');
        _nativeAddWord = _dylib!.lookupFunction<_HarperAddWordC, _HarperAddWordDart>('harper_add_user_word');
        _nativeLintJson = _dylib!.lookupFunction<_HarperLintJsonC, _HarperLintJsonDart>('harper_lint_json');
        _nativeFreeString = _dylib!.lookupFunction<_HarperFreeStringC, _HarperFreeStringDart>('harper_free_string');

        if (_nativeCreate != null) {
          _nativeContext = _nativeCreate!(dialect.nativeCode);
        }
      }
    } catch (_) {
      // Native library not loaded (e.g. running in pure Dart test runner);
      // Fallback engine will be used automatically.
      _dylib = null;
      _nativeContext = null;
    }
  }

  void setDialect(EnglishDialect newDialect) {
    dialect = newDialect;
    if (_nativeDestroy != null && _nativeContext != null) {
      _nativeDestroy!(_nativeContext!);
    }
    if (_nativeCreate != null) {
      _nativeContext = _nativeCreate!(dialect.nativeCode);
      for (final word in _userDictionary) {
        _addWordToNative(word);
      }
    }
  }

  void addUserWord(String word) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return;
    _userDictionary.add(trimmed.toLowerCase());
    _addWordToNative(trimmed);
  }

  void removeUserWord(String word) {
    final trimmed = word.trim().toLowerCase();
    _userDictionary.remove(trimmed);
    // Refresh native context without the removed word
    setDialect(dialect);
  }

  void clearUserWords() {
    _userDictionary.clear();
    setDialect(dialect);
  }

  void _addWordToNative(String word) {
    if (_nativeAddWord != null && _nativeContext != null) {
      final nativeWord = word.toNativeUtf8();
      try {
        _nativeAddWord!(_nativeContext!, nativeWord);
      } finally {
        calloc.free(nativeWord);
      }
    }
  }

  /// Lints text and returns correction results.
  /// User writing NEVER leaves this device process.
  CorrectionResult lint({
    required String text,
    int revision = 0,
    List<ProtectedSpan> protectedSpans = const [],
  }) {
    final startTime = DateTime.now();
    final sourceHash = text.hashCode;

    if (text.trim().isEmpty) {
      return CorrectionResult(
        sourceText: text,
        sourceHash: sourceHash,
        sourceRevision: revision,
        correctedText: '',
        issues: const [],
        language: AppLanguage.english,
        engineName: isNativeAvailable ? 'Harper Native' : 'Dart Rules Fallback',
        latencyMs: 0,
        charCount: 0,
        wordCount: 0,
      );
    }

    if (isNativeAvailable) {
      final nativeResult = _lintViaNative(text, revision, sourceHash, startTime, protectedSpans);
      if (nativeResult != null) {
        return nativeResult;
      }
    }

    // Fallback: rule-based English GEC & spell check engine (NOT Harper native)
    return _lintViaFallback(text, revision, sourceHash, startTime, protectedSpans);
  }

  CorrectionResult? _lintViaNative(
    String text,
    int revision,
    int sourceHash,
    DateTime startTime,
    List<ProtectedSpan> protectedSpans,
  ) {
    try {
      final nativeText = text.toNativeUtf8();
      ffi.Pointer<Utf8>? resultPtr;
      try {
        resultPtr = _nativeLintJson!(_nativeContext!, nativeText);
        if (resultPtr != ffi.nullptr) {
          final jsonStr = resultPtr.toDartString();
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final rawIssues = data['issues'] as List<dynamic>? ?? [];

          final issues = rawIssues
              .map((item) => CorrectionIssue.fromJson(item as Map<String, dynamic>))
              .where((issue) {
                if (_userDictionary.contains(issue.original.toLowerCase())) return false;
                if (!ProtectedSpanDetector.isEditAllowed(issue.start, issue.end, protectedSpans)) return false;
                return true;
              })
              .toList();

          final corrected = _buildFixedText(text, issues);
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;

          return CorrectionResult(
            sourceText: text,
            sourceHash: sourceHash,
            sourceRevision: revision,
            correctedText: corrected,
            issues: issues,
            language: AppLanguage.english,
            engineName: 'Harper Native',
            latencyMs: elapsed,
            charCount: text.length,
            wordCount: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
          );
        }
      } finally {
        calloc.free(nativeText);
        if (resultPtr != null && resultPtr != ffi.nullptr && _nativeFreeString != null) {
          _nativeFreeString!(resultPtr);
        }
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }

  /// Rule-based fallback engine replicating core Harper English linting
  CorrectionResult _lintViaFallback(
    String text,
    int revision,
    int sourceHash,
    DateTime startTime,
    List<ProtectedSpan> protectedSpans,
  ) {
    final issues = <CorrectionIssue>[];
    int issueId = 0;

    bool isSpanProtected(int start, int end) {
      return !ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans);
    }

    // 1. High-accuracy Grammar & Agreement Rules
    final grammarRules = [
      // Subject-verb agreement (plural nouns + is -> are, e.g. "The dogs is outside" -> "The dogs are outside")
      _Rule(
        pattern: RegExp(r'\b(The\s+[a-zA-Z]+s)\s+(is)\b', caseSensitive: false),
        replacement: (m) => '${m[1]} are',
        category: IssueCategory.agreement,
        message: 'Subject-verb agreement: use "are" with plural subjects',
      ),
      // "he/she don't" -> "he/she doesn't"
      _Rule(
        pattern: RegExp(r'\b(he|she|it)\s+(don)\x27t\b', caseSensitive: false),
        replacement: (m) => '${m[1]} doesn\'t',
        category: IssueCategory.agreement,
        message: 'Subject-verb agreement: use "doesn\'t" with third-person singular subjects',
      ),
      // "they/we/you doesn't" -> "they/we/you don't"
      _Rule(
        pattern: RegExp(r'\b(they|we|you)\s+(doesn)\x27t\b', caseSensitive: false),
        replacement: (m) => '${m[1]} don\'t',
        category: IssueCategory.agreement,
        message: 'Subject-verb agreement: use "don\'t" with plural subjects',
      ),
      // "I is/are" -> "I am"
      _Rule(
        pattern: RegExp(r'\b(I)\s+(is|are)\b'),
        replacement: (_) => 'I am',
        category: IssueCategory.agreement,
        message: 'Subject-verb agreement: use "am" with "I"',
      ),
      // "I has" -> "I have"
      _Rule(
        pattern: RegExp(r'\b(I)\s+(has)\b', caseSensitive: false),
        replacement: (m) => '${m[1]} have',
        category: IssueCategory.agreement,
        message: 'Subject-verb agreement: use "have" with "I"',
      ),
      // "he/she have" -> "he/she has"
      _Rule(
        pattern: RegExp(r'\b(he|she|it)\s+(have)\b', caseSensitive: false),
        replacement: (m) => '${m[1]} has',
        category: IssueCategory.agreement,
        message: 'Subject-verb agreement: use "has" with third-person subjects',
      ),
      // "we/they/you is/was" -> "are/were"
      _Rule(
        pattern: RegExp(r'\b(we|they|you)\s+(is|was)\b', caseSensitive: false),
        replacement: (m) => '${m[1]} ${m[2]!.toLowerCase() == 'is' ? 'are' : 'were'}',
        category: IssueCategory.agreement,
        message: 'Subject-verb agreement: use plural verb with plural subjects',
      ),
      // "he/she/it are/were" -> "is/was"
      _Rule(
        pattern: RegExp(r'\b(he|she|it)\s+(are|were)\b', caseSensitive: false),
        replacement: (m) => '${m[1]} ${m[2]!.toLowerCase() == 'are' ? 'is' : 'was'}',
        category: IssueCategory.agreement,
        message: 'Subject-verb agreement: use singular verb with third-person subjects',
      ),
      // Tense: "have/has/had went" -> "have/has/had gone"
      _Rule(
        pattern: RegExp(r'\b(have|has|had)\s+went\b', caseSensitive: false),
        replacement: (m) => '${m[1]} gone',
        category: IssueCategory.tense,
        message: 'Tense consistency: use past participle "gone" after auxiliary verb',
      ),
      // Tense: "will came" -> "will come"
      _Rule(
        pattern: RegExp(r'\b(will|shall|can|could|would|should|must)\s+came\b', caseSensitive: false),
        replacement: (m) => '${m[1]} come',
        category: IssueCategory.tense,
        message: 'Tense consistency: use base verb "come" after modal auxiliary',
      ),
      // Tense: "had saw" -> "had seen"
      _Rule(
        pattern: RegExp(r'\b(had|have|has)\s+saw\b', caseSensitive: false),
        replacement: (m) => '${m[1]} seen',
        category: IssueCategory.tense,
        message: 'Tense consistency: use past participle "seen" after auxiliary verb',
      ),
      // Profession articles: "is engineer" -> "is an engineer", "is teacher" -> "is a teacher", "is doctor" -> "is a doctor"
      _Rule(
        pattern: RegExp(r'\b(is|was|became)\s+(engineer|architect|artist)\b', caseSensitive: false),
        replacement: (m) => '${m[1]} an ${m[2]}',
        category: IssueCategory.grammar,
        message: 'Article: add "an" before singular profession starting with vowel sound',
      ),
      _Rule(
        pattern: RegExp(r'\b(is|was|became)\s+(teacher|doctor|lawyer|nurse|manager)\b', caseSensitive: false),
        replacement: (m) => '${m[1]} a ${m[2]}',
        category: IssueCategory.grammar,
        message: 'Article: add "a" before singular countable profession',
      ),
      // "a apple" -> "an apple"
      _Rule(
        pattern: RegExp(r'\b(a)\s+([aeiouAEIOU][a-zA-Z]+)\b'),
        replacement: (m) {
          final next = m[2]!.toLowerCase();
          // Exclude exceptions like "university", "unique", "european"
          if (next.startsWith('uni') || next.startsWith('use') || next.startsWith('euro')) {
            return m[0]!;
          }
          return 'an ${m[2]}';
        },
        category: IssueCategory.grammar,
        message: 'Use "an" before vowel sounds',
      ),
      // "an car" -> "a car"
      _Rule(
        pattern: RegExp(r'\b(an)\s+([^aeiouAEIOU\s][a-zA-Z]+)\b'),
        replacement: (m) {
          final next = m[2]!.toLowerCase();
          // Exclude exceptions like "hour", "honor", "honest"
          if (next.startsWith('hour') || next.startsWith('hono') || next.startsWith('honest')) {
            return m[0]!;
          }
          return 'a ${m[2]}';
        },
        category: IssueCategory.grammar,
        message: 'Use "a" before consonant sounds',
      ),
      // "could of" -> "could have"
      _Rule(
        pattern: RegExp(r'\b(could|should|would|must)\s+of\b', caseSensitive: false),
        replacement: (m) => '${m[1]} have',
        category: IssueCategory.grammar,
        message: 'Use modal auxiliary verb "have" instead of "of"',
      ),
      // Homophones: "Their going" -> "They're going"
      _Rule(
        pattern: RegExp(r'\b(their|there)\s+(going|coming|leaving|eating|staying)\b', caseSensitive: false),
        replacement: (m) => 'they\'re ${m[2]}',
        category: IssueCategory.wordChoice,
        message: 'Use contraction "they\'re" (they are) before present participle',
      ),
      // "Your right/welcome/wrong" -> "You're right/welcome/wrong"
      _Rule(
        pattern: RegExp(r'\b(your)\s+(welcome|right|wrong|good|here)\b', caseSensitive: false),
        replacement: (m) => 'you\'re ${m[2]}',
        category: IssueCategory.wordChoice,
        message: 'Use "you\'re" (you are) instead of possessive "your"',
      ),
      // "better then" -> "better than"
      _Rule(
        pattern: RegExp(r'\b(better|worse|more|less|faster|slower|bigger|smaller|taller|shorter|easier|harder)\s+then\b', caseSensitive: false),
        replacement: (m) => '${m[1]} than',
        category: IssueCategory.wordChoice,
        message: 'Use comparative "than" instead of temporal "then"',
      ),
    ];

    for (final rule in grammarRules) {
      for (final match in rule.pattern.allMatches(text)) {
        if (isSpanProtected(match.start, match.end)) continue;

        final orig = match.group(0)!;
        var repl = rule.replacement(match);

        // Preserve initial casing if original started with capital letter
        if (orig.isNotEmpty && orig[0] == orig[0].toUpperCase() && repl.isNotEmpty) {
          repl = repl[0].toUpperCase() + repl.substring(1);
        }

        if (orig != repl) {
          issues.add(
            CorrectionIssue(
              id: 'harper_gram_${++issueId}_${match.start}',
              engine: 'harper',
              category: rule.category,
              severity: IssueSeverity.warning,
              confidence: IssueConfidence.high,
              isAutoFixable: true,
              start: match.start,
              end: match.end,
              original: orig,
              suggestions: [repl],
              shortReason: 'Fix ${rule.category.displayName.toLowerCase()} "$orig" -> "$repl"',
              message: rule.message,
            ),
          );
        }
      }
    }

    // 2. Dialect Specific Spellings (US vs UK/AU/CA)
    final dialectMap = <String, String>{};
    if (dialect == EnglishDialect.british || dialect == EnglishDialect.australian) {
      dialectMap['color'] = 'colour';
      dialectMap['colors'] = 'colours';
      dialectMap['flavor'] = 'flavour';
      dialectMap['flavors'] = 'flavours';
      dialectMap['center'] = 'centre';
      dialectMap['centers'] = 'centres';
      dialectMap['theater'] = 'theatre';
      dialectMap['theaters'] = 'theatres';
      dialectMap['organize'] = 'organise';
      dialectMap['organized'] = 'organised';
      dialectMap['organizing'] = 'organising';
      dialectMap['analyze'] = 'analyse';
      dialectMap['analyzed'] = 'analysed';
      dialectMap['analyzing'] = 'analysing';
    } else if (dialect == EnglishDialect.american) {
      dialectMap['colour'] = 'color';
      dialectMap['colours'] = 'colors';
      dialectMap['flavour'] = 'flavor';
      dialectMap['flavours'] = 'flavors';
      dialectMap['centre'] = 'center';
      dialectMap['centres'] = 'centers';
      dialectMap['theatre'] = 'theater';
      dialectMap['theatres'] = 'theaters';
      dialectMap['organise'] = 'organize';
      dialectMap['organised'] = 'organized';
      dialectMap['organising'] = 'organizing';
      dialectMap['analyse'] = 'analyze';
      dialectMap['analysed'] = 'analyzed';
      dialectMap['analysing'] = 'analyzing';
    }

    final wordPattern = RegExp(r'\b[a-zA-Z]+\b');
    for (final match in wordPattern.allMatches(text)) {
      if (isSpanProtected(match.start, match.end)) continue;

      final word = match.group(0)!;
      final lower = word.toLowerCase();

      if (_userDictionary.contains(lower)) continue;

      if (dialectMap.containsKey(lower)) {
        var fix = dialectMap[lower]!;
        if (word[0] == word[0].toUpperCase() && fix.isNotEmpty) {
          fix = fix[0].toUpperCase() + fix.substring(1);
        }
        final isOverlapping = issues.any((i) => i.start <= match.start && i.end >= match.end);
        if (!isOverlapping) {
          issues.add(
            CorrectionIssue(
              id: 'harper_dialect_${++issueId}_${match.start}',
              engine: 'harper',
              category: IssueCategory.style,
              severity: IssueSeverity.suggestion,
              confidence: IssueConfidence.medium,
              isAutoFixable: false,
              start: match.start,
              end: match.end,
              original: word,
              suggestions: [fix],
              shortReason: 'Use ${dialect.displayName} spelling "$fix"',
              message: '${dialect.displayName} spelling: replace "$word" with "$fix"',
            ),
          );
        }
      } else {
        // Common spelling check in fallback mode
        final typoDict = {
          'teh': 'the',
          'recieve': 'receive',
          'recieved': 'received',
          'seperate': 'separate',
          'thsi': 'this',
          'becuase': 'because',
          'adn': 'and',
          'taht': 'that',
          'wierd': 'weird',
          'freind': 'friend',
          'occured': 'occurred',
          'untill': 'until',
          'truely': 'truly',
          'definately': 'definitely',
        };

        if (typoDict.containsKey(lower)) {
          var fix = typoDict[lower]!;
          if (word[0] == word[0].toUpperCase() && fix.isNotEmpty) {
            fix = fix[0].toUpperCase() + fix.substring(1);
          }
          final isOverlapping = issues.any((i) => i.start <= match.start && i.end >= match.end);
          if (!isOverlapping) {
            issues.add(
              CorrectionIssue(
                id: 'harper_typo_${++issueId}_${match.start}',
                engine: 'harper',
                category: IssueCategory.spelling,
                severity: IssueSeverity.warning,
                confidence: IssueConfidence.high,
                isAutoFixable: true,
                start: match.start,
                end: match.end,
                original: word,
                suggestions: [fix],
                shortReason: 'Fix typo "$word" -> "$fix"',
                message: 'Possible spelling mistake: replace "$word" with "$fix"',
              ),
            );
          }
        }
      }
    }

    // 3. Repeated Words (e.g. "the the")
    final repeatedWordPattern = RegExp(r'\b([a-zA-Z]+)\s+\1\b', caseSensitive: false);
    for (final match in repeatedWordPattern.allMatches(text)) {
      if (isSpanProtected(match.start, match.end)) continue;

      final orig = match.group(0)!;
      final word = match.group(1)!;
      // Skip intentional repetitions like "that that" or "had had" in valid constructions
      if (word.toLowerCase() == 'that' || word.toLowerCase() == 'had') continue;

      final isOverlapping = issues.any((i) => i.start <= match.start && i.end >= match.end);
      if (!isOverlapping) {
        issues.add(
          CorrectionIssue(
            id: 'harper_repeat_${++issueId}_${match.start}',
            engine: 'harper',
            category: IssueCategory.clarity,
            severity: IssueSeverity.warning,
            confidence: IssueConfidence.high,
            isAutoFixable: true,
            start: match.start,
            end: match.end,
            original: orig,
            suggestions: [word],
            shortReason: 'Remove duplicated word "$word"',
            message: 'Duplicate word: remove repeated "$word"',
          ),
        );
      }
    }

    // 4. Duplicate Punctuation (e.g. "..")
    final duplicatePunctPattern = RegExp(r'(?<!\.)\.\.(?!\.)');
    for (final match in duplicatePunctPattern.allMatches(text)) {
      if (isSpanProtected(match.start, match.end)) continue;
      issues.add(
        CorrectionIssue(
          id: 'harper_punct_${++issueId}_${match.start}',
          engine: 'harper',
          category: IssueCategory.punctuation,
          severity: IssueSeverity.warning,
          confidence: IssueConfidence.high,
          isAutoFixable: true,
          start: match.start,
          end: match.end,
          original: '..',
          suggestions: ['.'],
          shortReason: 'Replace duplicate periods with single period',
          message: 'Punctuation: replace duplicate periods with "."',
        ),
      );
    }

    // Sort issues by start offset
    issues.sort((a, b) => a.start.compareTo(b.start));

    final corrected = _buildFixedText(text, issues);
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;

    return CorrectionResult(
      sourceText: text,
      sourceHash: sourceHash,
      sourceRevision: revision,
      correctedText: corrected,
      issues: issues,
      language: AppLanguage.english,
      engineName: 'Dart Rules Fallback',
      latencyMs: elapsed,
      charCount: text.length,
      wordCount: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
    );
  }

  String _buildFixedText(String original, List<CorrectionIssue> issues) {
    if (issues.isEmpty) return original;
    final sorted = List<CorrectionIssue>.from(issues)..sort((a, b) => b.start.compareTo(a.start));
    var result = original;
    for (final issue in sorted) {
      if (issue.suggestions.isNotEmpty && issue.start >= 0 && issue.end <= result.length) {
        result = result.replaceRange(issue.start, issue.end, issue.suggestions.first);
      }
    }
    return result;
  }
}

class _Rule {
  final RegExp pattern;
  final String Function(Match) replacement;
  final IssueCategory category;
  final String message;

  _Rule({
    required this.pattern,
    required this.replacement,
    required this.category,
    required this.message,
  });
}
