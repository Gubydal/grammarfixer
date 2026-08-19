import '../entities/correction_issue.dart';
import 'protected_span_detector.dart';

/// Context-dependent English homophone, agreement, capitalization, and punctuation correction.
///
/// Uses multi-word patterns and structural context to detect errors that require surrounding context.
/// Supports retroactive correction: when later words disambiguate earlier words.
class EnglishContextRules {
  const EnglishContextRules();

  /// Finds context-dependent issues in [text].
  ///
  /// [protectedSpans] are excluded from any corrections.
  List<CorrectionIssue> findIssues(
    String text, {
    List<ProtectedSpan> protectedSpans = const [],
  }) {
    if (text.trim().isEmpty) return const [];

    final issues = <CorrectionIssue>[];

    // 1. Initial Sentence Capitalization & Greeting Rules
    _checkCapitalizationAndGreetings(text, issues, protectedSpans);

    // 2. Question terminal punctuation check
    _checkQuestionPunctuation(text, issues, protectedSpans);

    // 3. Pattern-based Context Rules
    for (final rule in _rules) {
      final matches = rule.pattern.allMatches(text);
      for (final match in matches) {
        final relStart = rule.targetGroupStart?.call(match) ?? 0;
        final start = match.start + relStart;
        final len = rule.targetGroupLength?.call(match) ?? (match.end - match.start);
        final end = start + len;

        if (start < 0 || end > text.length || start >= end) continue;

        final original = text.substring(start, end);

        // Skip if overlapping with a protected span
        if (!ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans)) {
          continue;
        }

        // Skip if we already have an issue at this span
        if (issues.any((i) => i.start < end && i.end > start)) continue;

        final replacement = rule.replacement(match, original);
        if (replacement == original) continue;

        issues.add(CorrectionIssue(
          id: 'ctx_${start}_$end',
          engine: 'context',
          category: rule.category,
          severity: rule.severity,
          confidence: rule.confidence,
          start: start,
          end: end,
          original: original,
          suggestions: [replacement],
          message: rule.message,
          shortReason: rule.shortReason,
          isAutoFixable: rule.isAutoFixable,
        ));
      }
    }

    return issues;
  }

  void _checkCapitalizationAndGreetings(
    String text,
    List<CorrectionIssue> issues,
    List<ProtectedSpan> protectedSpans,
  ) {
    // 1a. Greeting comma insertion at start: "hi can we" -> "Hi, can we" or "hello there" -> "Hello, there"
    final greetingMatch = RegExp(r'^\s*([Hh]i|[Hh]ello|[Hh]ey|[Dd]ear)\s+([a-zA-Z])').firstMatch(text);
    if (greetingMatch != null) {
      final greeting = greetingMatch.group(1)!;
      final start = text.indexOf(greeting);
      final end = start + greeting.length;
      final formatted = '${greeting[0].toUpperCase()}${greeting.substring(1)},';
      if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
          !issues.any((i) => i.start <= start && i.end >= end)) {
        issues.add(CorrectionIssue(
          id: 'greet_comma_${start}_$end',
          engine: 'context',
          category: IssueCategory.punctuation,
          severity: IssueSeverity.suggestion,
          confidence: IssueConfidence.high,
          start: start,
          end: end,
          original: greeting,
          suggestions: [formatted],
          message: 'Add a comma after the greeting.',
          shortReason: 'Punctuation',
          isAutoFixable: true,
        ));
      }
    } else {
      // 1b. First letter of text if lowercase (when not a greeting or informal acronym)
      final firstWordMatch = RegExp(r'^[ \t]*([a-zA-Z]+)').firstMatch(text);
      if (firstWordMatch != null) {
        final firstWord = firstWordMatch.group(1)!;
        const informalAcronyms = {'lol', 'omg', 'idk', 'btw', 'lmao', 'rofl', 'tbh', 'imho', 'imo', 'brb', 'gtg', 'smh'};
        if (!informalAcronyms.contains(firstWord.toLowerCase()) && firstWord[0] == firstWord[0].toLowerCase()) {
          final start = firstWordMatch.start + firstWordMatch.group(0)!.indexOf(firstWord);
          final end = start + 1;
          final orig = text.substring(start, end);
          if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
              !issues.any((i) => i.start <= start && i.end >= end)) {
            issues.add(CorrectionIssue(
              id: 'cap_start_${start}_$end',
              engine: 'context',
              category: IssueCategory.capitalization,
              severity: IssueSeverity.warning,
              confidence: IssueConfidence.high,
              start: start,
              end: end,
              original: orig,
              suggestions: [orig.toUpperCase()],
              message: 'Capitalize the first letter of the sentence.',
              shortReason: 'Capitalization',
              isAutoFixable: true,
            ));
          }
        }
      }
    }

    // 1c. Standalone lowercase "i" -> "I"
    final standaloneIMatches = RegExp(r'(?<=\s|^)(i)(?=\s|[\.,!?;:\x27"]|$)').allMatches(text);
    for (final match in standaloneIMatches) {
      final start = match.start;
      final end = match.end;
      if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
          !issues.any((i) => i.start <= start && i.end >= end)) {
        issues.add(CorrectionIssue(
          id: 'cap_i_${start}_$end',
          engine: 'context',
          category: IssueCategory.capitalization,
          severity: IssueSeverity.warning,
          confidence: IssueConfidence.high,
          start: start,
          end: end,
          original: 'i',
          suggestions: ['I'],
          message: 'Capitalize the pronoun "I".',
          shortReason: 'Capitalization',
          isAutoFixable: true,
        ));
      }
    }

    // 1d. Capitalization after terminal punctuation (. ! ?)
    final afterPunctMatches = RegExp(r'([\.\!\?]\s+)([a-z])').allMatches(text);
    for (final match in afterPunctMatches) {
      final letter = match.group(2)!;
      final start = match.start + match.group(1)!.length;
      final end = start + 1;
      if (ProtectedSpanDetector.isEditAllowed(start, end, protectedSpans) &&
          !issues.any((i) => i.start <= start && i.end >= end)) {
        issues.add(CorrectionIssue(
          id: 'cap_punct_${start}_$end',
          engine: 'context',
          category: IssueCategory.capitalization,
          severity: IssueSeverity.warning,
          confidence: IssueConfidence.high,
          start: start,
          end: end,
          original: letter,
          suggestions: [letter.toUpperCase()],
          message: 'Capitalize the first letter after sentence punctuation.',
          shortReason: 'Capitalization',
          isAutoFixable: true,
        ));
      }
    }
  }

  void _checkQuestionPunctuation(
    String text,
    List<CorrectionIssue> issues,
    List<ProtectedSpan> protectedSpans,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Check if sentence starts with question auxiliary words and does not end with punctuation
    final isQuestionStart = RegExp(
      r'^\s*(?:hi,?\s+|hello,?\s+|hey,?\s+|dear,?\s+)?(can|could|would|will|shall|should|may|might|do|does|did|is|are|am|was|were|has|have|had|how|what|why|where|when|who|which)\b',
      caseSensitive: false,
    ).hasMatch(trimmed);

    final endsWithPunct = RegExp(r'[\.\!\?]$').hasMatch(trimmed);

    if (isQuestionStart && !endsWithPunct) {
      final endPos = text.trimRight().length;

      issues.add(CorrectionIssue(
        id: 'punct_question_$endPos',
        engine: 'context',
        category: IssueCategory.punctuation,
        severity: IssueSeverity.warning,
        confidence: IssueConfidence.high,
        start: endPos,
        end: endPos,
        original: '',
        suggestions: ['?'],
        message: 'This sentence looks like a question. Add a question mark at the end.',
        shortReason: 'Punctuation',
        isAutoFixable: true,
      ));
    }
  }

  // ─────────────────── Rule Definitions ───────────────────

  static final List<_ContextRule> _rules = [
    // ── Plural Noun Agreement with "we / they / you" ──

    // "we/they/you/us" + "be/become/stay/remain" + singular noun -> plural noun
    // e.g. "can we be friend" -> "can we be friends", "we are friend" -> "we are friends"
    _ContextRule(
      pattern: RegExp(
        r'\b(we|they|you|us)\s+(be|become|stay|remain|are|were)\s+(friend|student|doctor|member|partner|enemy|colleague|neighbor|roommate)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1 + m.group(2)!.length + 1,
      targetGroupLength: (m) => m.group(3)!.length,
      replacement: (m, orig) => '${orig}s',
      message: 'Plural agreement: use plural noun with plural subject.',
      shortReason: 'Agreement',
      category: IssueCategory.agreement,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "one of my" + singular -> plural (e.g. "one of my friend" -> "one of my friends")
    _ContextRule(
      pattern: RegExp(
        r'\b(one\s+of\s+(?:my|our|their|his|her|the))\s+(friend|student|doctor|colleague|book|car|problem|option)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) => '${orig}s',
      message: 'Use plural noun after "one of my/the".',
      shortReason: 'Agreement',
      category: IssueCategory.agreement,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "many/several/few/both" + singular -> plural (e.g. "many friend" -> "many friends")
    _ContextRule(
      pattern: RegExp(
        r'\b(many|several|few|both|two|three|four|five|ten)\s+(friend|student|doctor|colleague|book|car|problem|option|reason|item)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) => '${orig}s',
      message: 'Use plural noun after quantifier.',
      shortReason: 'Agreement',
      category: IssueCategory.agreement,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── their / there / they're ──

    // "their" + verb/gerund → "they're"
    _ContextRule(
      pattern: RegExp(
        r'\b([Tt]heir)\s+(going|coming|leaving|arriving|running|walking|playing|trying|doing|making|getting|having|being|not\b)',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => 0,
      targetGroupLength: (m) => m.group(1)!.length,
      replacement: (m, orig) => _preserveCase(orig, "they're"),
      message: "Did you mean \"they're\" (they are)?",
      shortReason: 'Word choice',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── your / you're ──

    // "your" + verb/gerund/predicate → "you're"
    _ContextRule(
      pattern: RegExp(
        r"\b([Yy]our)\s+(going|coming|being|getting|making|doing|not|right|welcome|the\s+best|so\s+right|absolutely)\b",
        caseSensitive: false,
      ),
      targetGroupStart: (m) => 0,
      targetGroupLength: (m) => m.group(1)!.length,
      replacement: (m, orig) => _preserveCase(orig, "you're"),
      message: "Did you mean \"you're\" (you are)?",
      shortReason: 'Word choice',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── to / too / two ──

    // "too" + verb → "to"
    _ContextRule(
      pattern: RegExp(
        r'\b(too)\s+(go|come|get|make|do|be|have|take|give|see|know|find|want|need|tell|ask|try|call|leave|run|work|think|look|say|help|turn|show|play|move|pay|meet|read|learn|put|keep|set|hold|bring|write|sit|stand|begin|grow|open|walk|feel|start|stop)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => 0,
      targetGroupLength: (m) => m.group(1)!.length,
      replacement: (m, orig) => _preserveCase(orig, 'to'),
      message: 'Did you mean "to" (preposition)?',
      shortReason: 'Word choice',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "need to" / "want to" etc. — catch "need too go"
    _ContextRule(
      pattern: RegExp(
        r'\b(need|want|have|got|going|try|like|love|hate|used|ought|able)\s+(too)\s+(\w+)',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) => 'to',
      message: 'Did you mean "to" (preposition)?',
      shortReason: 'Word choice',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── its / it's ──

    // "its" + verb → "it's"
    _ContextRule(
      pattern: RegExp(
        r"\b([Ii]ts)\s+(going|coming|not|been|getting|a\s|the\s|very|so\s|really|about|important|clear|obvious|true|possible|likely)",
        caseSensitive: false,
      ),
      targetGroupStart: (m) => 0,
      targetGroupLength: (m) => m.group(1)!.length,
      replacement: (m, orig) => _preserveCase(orig, "it's"),
      message: "Did you mean \"it's\" (it is)?",
      shortReason: 'Word choice',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── then / than ──

    // "better/more/less/rather/other" + "then" → "than"
    _ContextRule(
      pattern: RegExp(
        r'\b(better|more|less|rather|other|greater|faster|slower|bigger|smaller|higher|lower|easier|harder|worse|nicer|older|younger|taller|shorter|longer|further)\s+(then)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) => 'than',
      message: 'Did you mean "than" (comparison)?',
      shortReason: 'Word choice',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── could of / should of / would of ──

    _ContextRule(
      pattern: RegExp(
        r'\b(could|should|would|must|might)\s+(of)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) => 'have',
      message: 'Did you mean "have"?',
      shortReason: 'Grammar',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── subject-verb agreement ──

    // "I has" → "I have"
    _ContextRule(
      pattern: RegExp(r'\b(I)\s+(has)\b'),
      targetGroupStart: (m) => 2,
      targetGroupLength: (m) => 3,
      replacement: (m, orig) => 'have',
      message: 'Subject-verb agreement: "I have".',
      shortReason: 'Agreement',
      category: IssueCategory.agreement,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "The dogs is" → "The dogs are"
    _ContextRule(
      pattern: RegExp(
        r'\b([Tt]he\s+\w+s)\s+(is)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => 2,
      replacement: (m, orig) => 'are',
      message: 'Subject-verb agreement: plural subject needs "are".',
      shortReason: 'Agreement',
      category: IssueCategory.agreement,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "He/She don't" → "doesn't"
    _ContextRule(
      pattern: RegExp(
        r"\b([Hh]e|[Ss]he|[Ii]t)\s+(don't|dont)\b",
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) => "doesn't",
      message: "Subject-verb agreement: use \"doesn't\" with he/she/it.",
      shortReason: 'Agreement',
      category: IssueCategory.agreement,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── tense ──

    // "have went" → "have gone"
    _ContextRule(
      pattern: RegExp(
        r'\b(have|has|had)\s+(went)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => 4,
      replacement: (m, orig) => 'gone',
      message: 'Verb tense: use "gone" with have/has/had.',
      shortReason: 'Tense',
      category: IssueCategory.tense,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "will came" → "will come"
    _ContextRule(
      pattern: RegExp(
        r'\b(will|shall|would|could|should|might|may|must|can)\s+(came)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => 4,
      replacement: (m, orig) => 'come',
      message: 'Verb tense: use base form after modals.',
      shortReason: 'Tense',
      category: IssueCategory.tense,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── ESL Preposition Collocations ──

    // "congratulate for/about" → "congratulate on"
    _ContextRule(
      pattern: RegExp(
        r'\b(congratulate|congratulated|congratulating)\s+([a-zA-Z]+)\s+(for|about)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1 + m.group(2)!.length + 1,
      targetGroupLength: (m) => m.group(3)!.length,
      replacement: (m, orig) => 'on',
      message: 'Preposition: use "congratulate on" rather than "for/about".',
      shortReason: 'Preposition',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "depends of/from" → "depends on"
    _ContextRule(
      pattern: RegExp(
        r'\b(depend|depends|depended|depending)\s+(of|from)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) => 'on',
      message: 'Preposition: use "depend on".',
      shortReason: 'Preposition',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "married with" → "married to"
    _ContextRule(
      pattern: RegExp(
        r'\b(married)\s+(with)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => 4,
      replacement: (m, orig) => 'to',
      message: 'Preposition: use "married to".',
      shortReason: 'Preposition',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "good/bad in" → "good/bad at"
    _ContextRule(
      pattern: RegExp(
        r'\b(good|bad|great|terrible|expert|skilled)\s+(in)\s+(math|english|sports|running|coding|writing|cooking|playing|singing|learning|speaking|drawing)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => 2,
      replacement: (m, orig) => 'at',
      message: 'Preposition: use "good/bad at" for skills.',
      shortReason: 'Preposition',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "look forward to + base verb" → "look forward to + gerund (-ing)"
    _ContextRule(
      pattern: RegExp(
        r'\b(look|looking|looks|looked)\s+forward\s+to\s+(hear|meet|see|talk|read|work|receive|visit|speak|join)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(0)!.length - m.group(2)!.length,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) {
        final verb = m.group(2)!.toLowerCase();
        if (verb == 'hear') return 'hearing';
        if (verb == 'meet') return 'meeting';
        if (verb == 'see') return 'seeing';
        if (verb == 'talk') return 'talking';
        if (verb == 'read') return 'reading';
        if (verb == 'work') return 'working';
        if (verb == 'receive') return 'receiving';
        if (verb == 'visit') return 'visiting';
        if (verb == 'speak') return 'speaking';
        if (verb == 'join') return 'joining';
        return '${verb}ing';
      },
      message: 'Grammar: "look forward to" is followed by a gerund (-ing form).',
      shortReason: 'Gerund form',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "interested for/about" → "interested in"
    _ContextRule(
      pattern: RegExp(
        r'\b(interested)\s+(for|about)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => m.group(2)!.length,
      replacement: (m, orig) => 'in',
      message: 'Preposition: use "interested in".',
      shortReason: 'Preposition',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "responsible of" → "responsible for"
    _ContextRule(
      pattern: RegExp(
        r'\b(responsible)\s+(of)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => 2,
      replacement: (m, orig) => 'for',
      message: 'Preposition: use "responsible for".',
      shortReason: 'Preposition',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "go to home" / "come to home" → "go home" / "come home"
    _ContextRule(
      pattern: RegExp(
        r'\b(go|goes|went|going|come|comes|came|coming)\s+(to\s+home)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => 7,
      replacement: (m, orig) => 'home',
      message: 'Idiom: omit "to" before "home".',
      shortReason: 'Word choice',
      category: IssueCategory.grammar,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "discuss about" → "discuss"
    _ContextRule(
      pattern: RegExp(
        r'\b(discuss|discussed|discussing|discusses)\s+(about)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => m.group(1)!.length + 1,
      targetGroupLength: (m) => 5,
      replacement: (m, orig) => '',
      message: 'Redundancy: "discuss" does not take "about".',
      shortReason: 'Redundancy',
      category: IssueCategory.clarity,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── Uncountable Noun Pluralization ──

    // "advices" → "advice"
    _ContextRule(
      pattern: RegExp(r'\b(advices)\b', caseSensitive: false),
      replacement: (m, orig) => _preserveCase(orig, 'advice'),
      message: '"Advice" is uncountable. Use "advice" or "pieces of advice".',
      shortReason: 'Uncountable noun',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "informations" → "information"
    _ContextRule(
      pattern: RegExp(r'\b(informations)\b', caseSensitive: false),
      replacement: (m, orig) => _preserveCase(orig, 'information'),
      message: '"Information" is uncountable. Use "information".',
      shortReason: 'Uncountable noun',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "equipments" → "equipment"
    _ContextRule(
      pattern: RegExp(r'\b(equipments)\b', caseSensitive: false),
      replacement: (m, orig) => _preserveCase(orig, 'equipment'),
      message: '"Equipment" is uncountable. Use "equipment".',
      shortReason: 'Uncountable noun',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "furnitures" → "furniture"
    _ContextRule(
      pattern: RegExp(r'\b(furnitures)\b', caseSensitive: false),
      replacement: (m, orig) => _preserveCase(orig, 'furniture'),
      message: '"Furniture" is uncountable. Use "furniture".',
      shortReason: 'Uncountable noun',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "homeworks" → "homework"
    _ContextRule(
      pattern: RegExp(r'\b(homeworks)\b', caseSensitive: false),
      replacement: (m, orig) => _preserveCase(orig, 'homework'),
      message: '"Homework" is uncountable. Use "homework".',
      shortReason: 'Uncountable noun',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "feedbacks" → "feedback"
    _ContextRule(
      pattern: RegExp(r'\b(feedbacks)\b', caseSensitive: false),
      replacement: (m, orig) => _preserveCase(orig, 'feedback'),
      message: '"Feedback" is uncountable. Use "feedback".',
      shortReason: 'Uncountable noun',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── Collocations & Common Verb Confusions ──

    // "make a research / make research" → "do research"
    _ContextRule(
      pattern: RegExp(
        r'\b(make|making|made|makes)\s+(a\s+research|research)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => 0,
      targetGroupLength: (m) => m.group(0)!.length,
      replacement: (m, orig) {
        final verb = m.group(1)!.toLowerCase();
        if (verb == 'made') return 'did research';
        if (verb == 'making') return 'doing research';
        if (verb == 'makes') return 'does research';
        return 'do research';
      },
      message: 'Collocation: use "do research" or "conduct research" instead of "make research".',
      shortReason: 'Collocation',
      category: IssueCategory.wordChoice,
      severity: IssueSeverity.warning,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // ── Article Corrections (a vs an phonetic rules) ──

    // "an university/unique/union/user/useful" → "a university/..."
    _ContextRule(
      pattern: RegExp(
        r'\b(an)\s+(university|unique|union|user|useful|uniform|unit|universal|useless)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => 0,
      targetGroupLength: (m) => 2,
      replacement: (m, orig) => _preserveCase(orig, 'a'),
      message: 'Article: use "a" before words starting with a consonant "y" sound.',
      shortReason: 'Article',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "a hour/honest/honor" → "an hour/..."
    _ContextRule(
      pattern: RegExp(
        r'\b(a)\s+(hour|hours|honest|honor|honour|heir)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => 0,
      targetGroupLength: (m) => 1,
      replacement: (m, orig) => _preserveCase(orig, 'an'),
      message: 'Article: use "an" before words starting with a silent "h".',
      shortReason: 'Article',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),

    // "an European/one" → "a European/one"
    _ContextRule(
      pattern: RegExp(
        r'\b(an)\s+(European|one-time|one-way|one)\b',
        caseSensitive: false,
      ),
      targetGroupStart: (m) => 0,
      targetGroupLength: (m) => 2,
      replacement: (m, orig) => _preserveCase(orig, 'a'),
      message: 'Article: use "a" before consonant sound.',
      shortReason: 'Article',
      category: IssueCategory.grammar,
      severity: IssueSeverity.error,
      confidence: IssueConfidence.high,
      isAutoFixable: true,
    ),
  ];

  /// Preserves the case pattern of [original] on [replacement].
  static String _preserveCase(String original, String replacement) {
    if (original.isEmpty || replacement.isEmpty) return replacement;
    if (original == original.toUpperCase() && original.length > 1) {
      return replacement.toUpperCase();
    }
    if (original[0] == original[0].toUpperCase()) {
      return replacement[0].toUpperCase() + replacement.substring(1);
    }
    return replacement;
  }
}

/// Internal rule definition for context-dependent corrections.
class _ContextRule {
  const _ContextRule({
    required this.pattern,
    this.targetGroupStart,
    this.targetGroupLength,
    required this.replacement,
    required this.message,
    required this.shortReason,
    required this.category,
    required this.severity,
    required this.confidence,
    this.isAutoFixable = false,
  });

  /// Regex pattern to match context.
  final RegExp pattern;

  /// Function returning the relative offset of the target within the match.
  final int Function(RegExpMatch match)? targetGroupStart;

  /// Function returning the length of the target span to replace.
  final int Function(RegExpMatch match)? targetGroupLength;

  /// Returns the corrected string for the target span.
  final String Function(RegExpMatch match, String original) replacement;

  final String message;
  final String shortReason;
  final IssueCategory category;
  final IssueSeverity severity;
  final IssueConfidence confidence;
  final bool isAutoFixable;
}
