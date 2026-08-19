enum IssueCategory {
  grammar('Grammar'),
  spelling('Spelling'),
  punctuation('Punctuation'),
  agreement('Agreement'),
  tense('Tense'),
  wordChoice('Word Choice'),
  wordBoundary('Word Boundary'),
  capitalization('Capitalization'),
  style('Style'),
  clarity('Clarity'),
  other('Other');

  const IssueCategory(this.displayName);
  final String displayName;

  static IssueCategory fromString(String cat) {
    final lower = cat.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (lower.contains('spell') || lower.contains('typo')) {
      return IssueCategory.spelling;
    }
    if (lower.contains('punct') || lower.contains('comma') || lower.contains('period') || lower.contains('quote') || lower.contains('apostrophe')) {
      return IssueCategory.punctuation;
    }
    if (lower.contains('agree') || lower.contains('subject verb') || lower.contains('number')) {
      return IssueCategory.agreement;
    }
    if (lower.contains('tense') || lower.contains('verb form') || lower.contains('past') || lower.contains('present')) {
      return IssueCategory.tense;
    }
    if (lower.contains('word bound') || lower.contains('joined') || lower.contains('split')) {
      return IssueCategory.wordBoundary;
    }
    if (lower.contains('cap') || lower.contains('casing') || lower.contains('uppercase') || lower.contains('lowercase')) {
      return IssueCategory.capitalization;
    }
    if (lower.contains('word choice') || lower.contains('homophone') || lower.contains('confused')) {
      return IssueCategory.wordChoice;
    }
    if (lower.contains('style') || lower.contains('dialect') || lower.contains('formal') || lower.contains('informal')) {
      return IssueCategory.style;
    }
    if (lower.contains('clarity') || lower.contains('concision') || lower.contains('flow')) {
      return IssueCategory.clarity;
    }
    if (lower.contains('gramm') || lower.contains('article') || lower.contains('preposition') || lower.contains('pronoun')) {
      return IssueCategory.grammar;
    }
    return IssueCategory.grammar;
  }
}

enum IssueSeverity {
  error,
  warning,
  suggestion;

  static IssueSeverity fromString(String sev) {
    final lower = sev.toLowerCase();
    if (lower.contains('err')) return IssueSeverity.error;
    if (lower.contains('sugg') || lower.contains('hint') || lower.contains('info')) return IssueSeverity.suggestion;
    return IssueSeverity.warning;
  }
}

enum IssueConfidence {
  high,
  medium,
  low;

  static IssueConfidence fromString(String conf) {
    final lower = conf.toLowerCase();
    if (lower.contains('high') || lower == '1' || lower == '0.9') return IssueConfidence.high;
    if (lower.contains('low') || lower == '0.3' || lower == '0.4') return IssueConfidence.low;
    return IssueConfidence.medium;
  }
}

class CorrectionIssue {
  const CorrectionIssue({
    required this.id,
    required this.engine,
    required this.category,
    required this.severity,
    required this.start,
    required this.end,
    required this.original,
    required this.suggestions,
    required this.message,
    this.shortReason,
    this.confidence = IssueConfidence.medium,
    this.isAutoFixable = false,
    this.isIgnored = false,
    this.isApplied = false,
    this.appliedReplacement,
  });

  final String id;
  final String engine; // 'harper' | 'typo' | 'qwen' | 'merger'
  final IssueCategory category;
  final IssueSeverity severity;
  final IssueConfidence confidence;
  final int start;
  final int end;
  final String original;
  final List<String> suggestions;
  final String message;
  final String? shortReason;
  final bool isAutoFixable;
  final bool isIgnored;
  final bool isApplied;
  final String? appliedReplacement;

  String get topSuggestion => suggestions.isNotEmpty ? suggestions.first : '';

  CorrectionIssue copyWith({
    String? id,
    String? engine,
    IssueCategory? category,
    IssueSeverity? severity,
    IssueConfidence? confidence,
    int? start,
    int? end,
    String? original,
    List<String>? suggestions,
    String? message,
    String? shortReason,
    bool? isAutoFixable,
    bool? isIgnored,
    bool? isApplied,
    String? appliedReplacement,
  }) {
    return CorrectionIssue(
      id: id ?? this.id,
      engine: engine ?? this.engine,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      start: start ?? this.start,
      end: end ?? this.end,
      original: original ?? this.original,
      suggestions: suggestions ?? this.suggestions,
      message: message ?? this.message,
      shortReason: shortReason ?? this.shortReason,
      isAutoFixable: isAutoFixable ?? this.isAutoFixable,
      isIgnored: isIgnored ?? this.isIgnored,
      isApplied: isApplied ?? this.isApplied,
      appliedReplacement: appliedReplacement ?? this.appliedReplacement,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'engine': engine,
        'category': category.name,
        'severity': severity.name,
        'confidence': confidence.name,
        'start': start,
        'end': end,
        'original': original,
        'suggestions': suggestions,
        'message': message,
        'shortReason': shortReason,
        'isAutoFixable': isAutoFixable,
        'isIgnored': isIgnored,
        'isApplied': isApplied,
        'appliedReplacement': appliedReplacement,
      };

  factory CorrectionIssue.fromJson(Map<String, dynamic> json) {
    return CorrectionIssue(
      id: json['id'] as String? ?? UniqueKey().toString(),
      engine: json['engine'] as String? ?? 'harper',
      category: IssueCategory.fromString(json['category'] as String? ?? 'grammar'),
      severity: IssueSeverity.fromString(json['severity'] as String? ?? 'warning'),
      confidence: IssueConfidence.fromString(json['confidence'] as String? ?? 'medium'),
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
      original: json['original'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
      message: json['message'] as String? ?? '',
      shortReason: json['shortReason'] as String?,
      isAutoFixable: json['isAutoFixable'] as bool? ?? false,
      isIgnored: json['isIgnored'] as bool? ?? false,
      isApplied: json['isApplied'] as bool? ?? false,
      appliedReplacement: json['appliedReplacement'] as String?,
    );
  }
}

class UniqueKey {
  static int _counter = 0;
  @override
  String toString() => 'issue_${DateTime.now().millisecondsSinceEpoch}_${++_counter}';
}
