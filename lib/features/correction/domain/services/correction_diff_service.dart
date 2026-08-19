import '../entities/correction_issue.dart';

enum DiffOperation { delete, insert, equal }

class DiffChunk {
  const DiffChunk(this.operation, this.text);
  final DiffOperation operation;
  final String text;

  @override
  String toString() => '${operation.name}: "$text"';
}

/// Computes granular replacement spans between original text and corrected text.
///
/// Converts full-sentence LLM/engine outputs into interactive, reviewable
/// edits with word-level precision across all supported languages (including Arabic RTL).
class CorrectionDiffService {
  const CorrectionDiffService();

  /// Computes a list of [CorrectionIssue] differences between [original] and [corrected].
  List<CorrectionIssue> computeIssues(
    String original,
    String corrected, {
    String engine = 'qwen',
  }) {
    if (original == corrected || original.trim().isEmpty) {
      return const [];
    }

    final tokens1 = _tokenize(original);
    final tokens2 = _tokenize(corrected);

    final lcsMatrix = _computeLcs(tokens1, tokens2);
    final diffs = _backtrack(tokens1, tokens2, lcsMatrix);

    final issues = <CorrectionIssue>[];
    var originalOffset = 0;
    var issueCounter = 0;

    var i = 0;
    while (i < diffs.length) {
      final current = diffs[i];

      if (current.operation == DiffOperation.equal) {
        originalOffset += current.text.length;
        i++;
      } else if (current.operation == DiffOperation.delete) {
        final delText = current.text;
        final startPos = originalOffset;
        final endPos = originalOffset + delText.length;
        originalOffset += delText.length;

        String replacement = '';
        if (i + 1 < diffs.length && diffs[i + 1].operation == DiffOperation.insert) {
          replacement = diffs[i + 1].text;
          i += 2;
        } else {
          i++;
        }

        if (delText.trim().isNotEmpty || replacement.trim().isNotEmpty) {
          final category = _categorizeEdit(delText, replacement);
          issues.add(
            CorrectionIssue(
              id: '${engine}_diff_${++issueCounter}_$startPos',
              engine: engine,
              category: category,
              severity: IssueSeverity.warning,
              start: startPos,
              end: endPos,
              original: delText,
              suggestions: replacement.isNotEmpty ? [replacement] : const [],
              message: replacement.isNotEmpty
                  ? 'Replace "$delText" with "$replacement"'
                  : 'Remove "$delText"',
            ),
          );
        }
      } else if (current.operation == DiffOperation.insert) {
        final insText = current.text;
        final startPos = originalOffset;
        final endPos = originalOffset;

        if (insText.trim().isNotEmpty) {
          final category = _categorizeEdit('', insText);
          issues.add(
            CorrectionIssue(
              id: '${engine}_diff_${++issueCounter}_$startPos',
              engine: engine,
              category: category,
              severity: IssueSeverity.suggestion,
              start: startPos,
              end: endPos,
              original: '',
              suggestions: [insText],
              message: 'Add missing "$insText"',
            ),
          );
        }
        i++;
      }
    }

    return issues;
  }

  List<String> _tokenize(String text) {
    final tokens = <String>[];
    final regex = RegExp(r'(\s+|[^\s\w]+|[\w\u0600-\u06FF]+)');
    for (final match in regex.allMatches(text)) {
      tokens.add(match.group(0)!);
    }
    return tokens;
  }

  List<List<int>> _computeLcs(List<String> a, List<String> b) {
    final n = a.length;
    final m = b.length;
    final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));

    for (var i = 0; i < n; i++) {
      for (var j = 0; j < m; j++) {
        if (a[i] == b[j]) {
          lcs[i + 1][j + 1] = lcs[i][j] + 1;
        } else {
          final top = lcs[i][j + 1];
          final left = lcs[i + 1][j];
          lcs[i + 1][j + 1] = top > left ? top : left;
        }
      }
    }
    return lcs;
  }

  List<DiffChunk> _backtrack(
    List<String> a,
    List<String> b,
    List<List<int>> lcs,
  ) {
    var i = a.length;
    var j = b.length;
    final result = <DiffChunk>[];

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && a[i - 1] == b[j - 1]) {
        result.add(DiffChunk(DiffOperation.equal, a[i - 1]));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || lcs[i][j - 1] >= lcs[i - 1][j])) {
        result.add(DiffChunk(DiffOperation.insert, b[j - 1]));
        j--;
      } else if (i > 0 && (j == 0 || lcs[i][j - 1] < lcs[i - 1][j])) {
        result.add(DiffChunk(DiffOperation.delete, a[i - 1]));
        i--;
      }
    }

    final reversed = result.reversed.toList();
    return _mergeAdjacentChunks(reversed);
  }

  List<DiffChunk> _mergeAdjacentChunks(List<DiffChunk> chunks) {
    if (chunks.isEmpty) return [];

    final merged = <DiffChunk>[];
    var currentOp = chunks.first.operation;
    var currentText = StringBuffer(chunks.first.text);

    for (var i = 1; i < chunks.length; i++) {
      final chunk = chunks[i];
      if (chunk.operation == currentOp) {
        currentText.write(chunk.text);
      } else {
        merged.add(DiffChunk(currentOp, currentText.toString()));
        currentOp = chunk.operation;
        currentText = StringBuffer(chunk.text);
      }
    }
    merged.add(DiffChunk(currentOp, currentText.toString()));
    return merged;
  }

  IssueCategory _categorizeEdit(String original, String replacement) {
    final origTrim = original.trim();
    final replTrim = replacement.trim();

    if (origTrim.isEmpty || replTrim.isEmpty) {
      if (RegExp(r'^[.,!?;:،]+$').hasMatch(origTrim.isNotEmpty ? origTrim : replTrim)) {
        return IssueCategory.punctuation;
      }
      return IssueCategory.clarity;
    }

    if (RegExp(r'^[.,!?;:،]+$').hasMatch(origTrim) && RegExp(r'^[.,!?;:،]+$').hasMatch(replTrim)) {
      return IssueCategory.punctuation;
    }

    if (origTrim.toLowerCase() == replTrim.toLowerCase()) {
      return IssueCategory.spelling;
    }

    final lev = _levenshtein(origTrim.toLowerCase(), replTrim.toLowerCase());
    if (lev <= 2 && origTrim.length > 3) {
      return IssueCategory.spelling;
    }

    return IssueCategory.grammar;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < t.length; j++) {
        final cost = (s[i] == t[j]) ? 0 : 1;
        final val1 = v1[j] + 1;
        final val2 = v0[j + 1] + 1;
        final val3 = v0[j] + cost;
        var min = val1 < val2 ? val1 : val2;
        if (val3 < min) min = val3;
        v1[j + 1] = min;
      }
      for (var j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }
}
