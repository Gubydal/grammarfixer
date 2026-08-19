import '../entities/correction_issue.dart';
import '../entities/correction_mode.dart';
import '../entities/writing_style_profile.dart';
import 'protected_span_detector.dart';

/// Merges candidate corrections from multiple local engines (Typo Engine, Harper, Model)
/// into a coherent, non-conflicting, prioritized list of issues.
class CorrectionMerger {
  const CorrectionMerger();

  /// Merges candidates from multiple engine streams.
  List<CorrectionIssue> merge({
    required String text,
    required List<CorrectionIssue> typoIssues,
    required List<CorrectionIssue> harperIssues,
    required List<CorrectionIssue> modelIssues,
    required WritingStyleProfile styleProfile,
    required CorrectionMode mode,
    List<ProtectedSpan> protectedSpans = const [],
  }) {
    if (text.isEmpty) return const [];

    // Combine all incoming candidate streams
    final allCandidates = <CorrectionIssue>[
      ...typoIssues,
      ...harperIssues,
      ...modelIssues,
    ];

    if (allCandidates.isEmpty) return const [];

    // 1. Filter out issues intersecting any protected span
    final validSpans = allCandidates.where((issue) {
      return ProtectedSpanDetector.isEditAllowed(issue.start, issue.end, protectedSpans);
    }).toList();

    // 2. Filter / Adapt based on WritingStyleProfile
    final styledCandidates = <CorrectionIssue>[];
    for (final issue in validSpans) {
      // Objective grammar, spelling, tense, and agreement are NEVER suppressed
      final isObjective = issue.category == IssueCategory.grammar ||
          issue.category == IssueCategory.spelling ||
          issue.category == IssueCategory.agreement ||
          issue.category == IssueCategory.tense ||
          issue.category == IssueCategory.wordBoundary;

      if (!isObjective && issue.category == IssueCategory.style) {
        // If this exact style suggestion was previously rejected, suppress it
        final patternKey = '${issue.original.toLowerCase()}->${issue.topSuggestion.toLowerCase()}';
        if (styleProfile.rejectedStylePatterns.contains(patternKey)) {
          continue;
        }

        // In 'correct' mode, suppress purely stylistic suggestions unless explicitly accepted
        if (mode == CorrectionMode.correct && !styleProfile.acceptedStylePatterns.contains(patternKey)) {
          continue;
        }
      }

      // Check if user has a preferred term substitution (e.g., specific brand name or spelling)
      final originalLower = issue.original.toLowerCase();
      if (styleProfile.preferredTerms.containsKey(originalLower)) {
        final preferred = styleProfile.preferredTerms[originalLower]!;
        styledCandidates.add(
          issue.copyWith(
            suggestions: [preferred, ...issue.suggestions.where((s) => s != preferred)],
            category: IssueCategory.style,
            confidence: IssueConfidence.high,
          ),
        );
        continue;
      }

      styledCandidates.add(issue);
    }

    // 3. Deduplicate and resolve overlapping spans
    // Sort primarily by start offset, and secondarily by confidence (high -> medium -> low)
    styledCandidates.sort((a, b) {
      final startCmp = a.start.compareTo(b.start);
      if (startCmp != 0) return startCmp;
      return _confidenceWeight(b.confidence).compareTo(_confidenceWeight(a.confidence));
    });

    final resolved = <CorrectionIssue>[];
    for (final candidate in styledCandidates) {
      if (candidate.suggestions.isEmpty) continue;
      // Skip if suggestion is identical to original
      if (candidate.suggestions.first.trim() == candidate.original.trim()) continue;

      // Check for conflict with an already accepted issue
      int conflictingIndex = -1;
      for (int i = 0; i < resolved.length; i++) {
        final existing = resolved[i];
        if (candidate.start < existing.end && candidate.end > existing.start) {
          conflictingIndex = i;
          break;
        }
      }

      if (conflictingIndex == -1) {
        // No overlap; add directly
        resolved.add(candidate);
      } else {
        // Overlap detected: resolve based on confidence and engine specificity
        final existing = resolved[conflictingIndex];
        final existingWeight = _confidenceWeight(existing.confidence);
        final candidateWeight = _confidenceWeight(candidate.confidence);

        if (candidateWeight > existingWeight) {
          // Replace lower-confidence existing issue with higher-confidence candidate
          resolved[conflictingIndex] = candidate;
        } else if (candidateWeight == existingWeight) {
          // If weights are equal, prefer deterministic typo/harper rules over generic model diffs
          if ((candidate.engine == 'typo' || candidate.engine == 'harper') && existing.engine == 'qwen') {
            resolved[conflictingIndex] = candidate;
          }
        }
      }
    }

    // Final sorting by start position
    resolved.sort((a, b) => a.start.compareTo(b.start));
    return resolved;
  }

  static int _confidenceWeight(IssueConfidence confidence) {
    switch (confidence) {
      case IssueConfidence.high:
        return 3;
      case IssueConfidence.medium:
        return 2;
      case IssueConfidence.low:
        return 1;
    }
  }
}
