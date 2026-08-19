import 'dart:convert';
import 'language.dart';

enum ContractionStyle {
  preferContractions,
  preferExpanded,
  neutral;

  static ContractionStyle fromString(String val) {
    switch (val) {
      case 'preferContractions':
        return ContractionStyle.preferContractions;
      case 'preferExpanded':
        return ContractionStyle.preferExpanded;
      default:
        return ContractionStyle.neutral;
    }
  }
}

enum OxfordCommaStyle {
  always,
  never,
  neutral;

  static OxfordCommaStyle fromString(String val) {
    switch (val) {
      case 'always':
        return OxfordCommaStyle.always;
      case 'never':
        return OxfordCommaStyle.never;
      default:
        return OxfordCommaStyle.neutral;
    }
  }
}

enum FormalityStyle {
  casual,
  neutral,
  formal;

  static FormalityStyle fromString(String val) {
    switch (val) {
      case 'casual':
        return FormalityStyle.casual;
      case 'formal':
        return FormalityStyle.formal;
      default:
        return FormalityStyle.neutral;
    }
  }
}

/// Represents the on-device user writing style preferences and adaptive signals.
///
/// CRITICAL PRIVACY & CORRECTNESS INVARIANTS:
/// 1. Stored exclusively on-device in SharedPreferences.
/// 2. Contains ONLY compact categorical signals and preferred word pairs. Never stores full user sentences.
/// 3. Objective grammar (e.g. subject-verb agreement "The dogs is") can NEVER be learned away.
class WritingStyleProfile {
  final EnglishDialect dialect;
  final ContractionStyle contractionsPreference;
  final OxfordCommaStyle oxfordCommaPreference;
  final FormalityStyle formalityPreference;
  final bool emojiPreservation;
  final bool allowCasualLowercase;
  final Map<String, String> preferredTerms;
  final Set<String> acceptedStylePatterns;
  final Set<String> rejectedStylePatterns;

  const WritingStyleProfile({
    this.dialect = EnglishDialect.american,
    this.contractionsPreference = ContractionStyle.neutral,
    this.oxfordCommaPreference = OxfordCommaStyle.neutral,
    this.formalityPreference = FormalityStyle.neutral,
    this.emojiPreservation = true,
    this.allowCasualLowercase = false,
    this.preferredTerms = const {},
    this.acceptedStylePatterns = const {},
    this.rejectedStylePatterns = const {},
  });

  WritingStyleProfile copyWith({
    EnglishDialect? dialect,
    ContractionStyle? contractionsPreference,
    OxfordCommaStyle? oxfordCommaPreference,
    FormalityStyle? formalityPreference,
    bool? emojiPreservation,
    bool? allowCasualLowercase,
    Map<String, String>? preferredTerms,
    Set<String>? acceptedStylePatterns,
    Set<String>? rejectedStylePatterns,
  }) {
    return WritingStyleProfile(
      dialect: dialect ?? this.dialect,
      contractionsPreference: contractionsPreference ?? this.contractionsPreference,
      oxfordCommaPreference: oxfordCommaPreference ?? this.oxfordCommaPreference,
      formalityPreference: formalityPreference ?? this.formalityPreference,
      emojiPreservation: emojiPreservation ?? this.emojiPreservation,
      allowCasualLowercase: allowCasualLowercase ?? this.allowCasualLowercase,
      preferredTerms: preferredTerms ?? this.preferredTerms,
      acceptedStylePatterns: acceptedStylePatterns ?? this.acceptedStylePatterns,
      rejectedStylePatterns: rejectedStylePatterns ?? this.rejectedStylePatterns,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dialect': dialect.name,
      'contractionsPreference': contractionsPreference.name,
      'oxfordCommaPreference': oxfordCommaPreference.name,
      'formalityPreference': formalityPreference.name,
      'emojiPreservation': emojiPreservation,
      'allowCasualLowercase': allowCasualLowercase,
      'preferredTerms': preferredTerms,
      'acceptedStylePatterns': acceptedStylePatterns.toList(),
      'rejectedStylePatterns': rejectedStylePatterns.toList(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory WritingStyleProfile.fromMap(Map<String, dynamic> map) {
    return WritingStyleProfile(
      dialect: EnglishDialect.fromString(map['dialect'] as String? ?? 'american'),
      contractionsPreference: ContractionStyle.fromString(map['contractionsPreference'] as String? ?? 'neutral'),
      oxfordCommaPreference: OxfordCommaStyle.fromString(map['oxfordCommaPreference'] as String? ?? 'neutral'),
      formalityPreference: FormalityStyle.fromString(map['formalityPreference'] as String? ?? 'neutral'),
      emojiPreservation: map['emojiPreservation'] as bool? ?? true,
      allowCasualLowercase: map['allowCasualLowercase'] as bool? ?? false,
      preferredTerms: Map<String, String>.from(map['preferredTerms'] as Map? ?? {}),
      acceptedStylePatterns: Set<String>.from(map['acceptedStylePatterns'] as List? ?? []),
      rejectedStylePatterns: Set<String>.from(map['rejectedStylePatterns'] as List? ?? []),
    );
  }

  factory WritingStyleProfile.fromJson(String source) {
    try {
      return WritingStyleProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return const WritingStyleProfile();
    }
  }
}
