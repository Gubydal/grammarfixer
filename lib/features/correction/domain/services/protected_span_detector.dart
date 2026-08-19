/// Represents a span of text that must never be altered or corrupted
/// by grammar/spelling/style correction engines.
class ProtectedSpan {
  final int start;
  final int end;
  final String text;
  final String type; // 'url', 'email', 'phone', 'username', 'hashtag', 'code', 'path', 'version', 'currency', 'sku', 'html'

  const ProtectedSpan({
    required this.start,
    required this.end,
    required this.text,
    required this.type,
  });

  bool contains(int index) => index >= start && index < end;
  bool overlaps(int otherStart, int otherEnd) => start < otherEnd && end > otherStart;

  @override
  String toString() => 'ProtectedSpan($type: "$text" [$start, $end])';
}

/// Identifies protected non-natural-language spans in user writing.
class ProtectedSpanDetector {
  // 1. URLs (http/https/ftp/www/domains)
  static final RegExp _urlRegex = RegExp(
    r'(?:https?:\/\/|www\.)[^\s<>"{}|\\^`\[\]]+|(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:\/[^\s<>"{}|\\^`\[\]]*)?',
    caseSensitive: false,
  );

  // 2. Email addresses
  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );

  // 3. Phone numbers (e.g. +1-800-555-0199, (123) 456-7890)
  static final RegExp _phoneRegex = RegExp(
    r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b',
  );

  // 4. Usernames & Mentions (@handle)
  static final RegExp _usernameRegex = RegExp(
    r'(?<=^|\s)@[a-zA-Z0-9_]{1,30}\b',
  );

  // 5. Hashtags (#tag)
  static final RegExp _hashtagRegex = RegExp(
    r'(?<=^|\s)#[a-zA-Z0-9_\u0600-\u06FF]{1,50}\b',
  );

  // 6. Code blocks / Markdown code fences & inline code (`...` or ```...```)
  static final RegExp _codeBlockRegex = RegExp(
    r'```[\s\S]*?```|`[^`\n]+`',
  );

  // 7. File paths & extensions (e.g. /usr/bin/env, C:\Code\app, lib/main.dart)
  static final RegExp _filePathRegex = RegExp(
    r'(?:[a-zA-Z]:\\|\/|\.\/|\.\.\/)[^\s<>"|?*]+\.[a-zA-Z0-9]{1,6}\b|\b[a-zA-Z0-9_-]+\/(?:[a-zA-Z0-9_-]+\/)*[a-zA-Z0-9_-]+\.[a-zA-Z0-9]{1,6}\b',
  );

  // 8. Version strings (e.g. v1.2.3, 3.29.0-rc1)
  static final RegExp _versionRegex = RegExp(
    r'\bv?\d+\.\d+(?:\.\d+)?(?:-[a-zA-Z0-9.]+)?\b',
  );

  // 9. Currencies (e.g. $100, €45.99, £20, ¥5000, 100 USD, 50 EUR)
  static final RegExp _currencyRegex = RegExp(
    r'[\$€£¥₹]\s?\d+(?:,\d{3})*(?:\.\d{1,2})?|\b\d+(?:,\d{3})*(?:\.\d{1,2})?\s?(?:USD|EUR|GBP|JPY|CAD|AUD|SAR|AED|EGP)\b',
  );

  // 10. SKUs, Serial numbers, Product IDs (e.g. SKU-12345, ABC-987-XYZ)
  static final RegExp _skuRegex = RegExp(
    r'\b[A-Z0-9]{3,}(?:-[A-Z0-9]+){1,4}\b',
  );

  // 11. HTML / XML tags (<div class="test">, </span >)
  static final RegExp _htmlRegex = RegExp(
    r'<[^>\n]+>',
  );

  /// Scans the source text and returns all non-overlapping protected spans.
  static List<ProtectedSpan> detect(String text) {
    if (text.isEmpty) return const [];

    final spans = <ProtectedSpan>[];

    void addMatches(RegExp regex, String type) {
      for (final match in regex.allMatches(text)) {
        final start = match.start;
        final end = match.end;
        final matchedText = match.group(0) ?? '';

        // Exclude common false positives (e.g., plain single dot at end of sentence)
        if (matchedText.trim().isEmpty) continue;

        // Check if overlaps with an already existing span
        final overlaps = spans.any((s) => s.overlaps(start, end));
        if (!overlaps) {
          spans.add(
            ProtectedSpan(
              start: start,
              end: end,
              text: matchedText,
              type: type,
            ),
          );
        }
      }
    }

    // Process from most specific / longest potential patterns to standard patterns
    addMatches(_codeBlockRegex, 'code');
    addMatches(_htmlRegex, 'html');
    addMatches(_emailRegex, 'email');
    addMatches(_urlRegex, 'url');
    addMatches(_filePathRegex, 'path');
    addMatches(_skuRegex, 'sku');
    addMatches(_phoneRegex, 'phone');
    addMatches(_currencyRegex, 'currency');
    addMatches(_usernameRegex, 'username');
    addMatches(_hashtagRegex, 'hashtag');
    addMatches(_versionRegex, 'version');

    // Sort by start offset
    spans.sort((a, b) => a.start.compareTo(b.start));
    return spans;
  }

  /// Checks whether a proposed edit interval [start, end] intersects any protected span.
  static bool isEditAllowed(int start, int end, List<ProtectedSpan> protectedSpans) {
    for (final span in protectedSpans) {
      if (span.overlaps(start, end)) {
        return false;
      }
    }
    return true;
  }
}
