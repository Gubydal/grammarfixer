class TextChunk {
  const TextChunk({
    required this.text,
    required this.separator,
    required this.originalOffset,
  });

  final String text;
  final String separator;
  final int originalOffset;
}

/// Splits long text safely by paragraph or sentence boundaries without
/// breaking inside URLs, numbers, emoji sequences, or formatting tokens.
class CorrectionChunker {
  const CorrectionChunker({
    this.maxChunkChars = 1200,
  });

  final int maxChunkChars;

  List<TextChunk> chunk(String text) {
    if (text.length <= maxChunkChars) {
      return [
        TextChunk(
          text: text,
          separator: '',
          originalOffset: 0,
        ),
      ];
    }

    final chunks = <TextChunk>[];
    // Split primarily by double newline (paragraphs)
    final paragraphs = text.split(RegExp(r'(?<=\n\n|\r\n\r\n)'));

    var currentBuffer = StringBuffer();
    var currentOffset = 0;
    var chunkStartOffset = 0;

    for (final para in paragraphs) {
      if (currentBuffer.length + para.length <= maxChunkChars) {
        if (currentBuffer.isEmpty) {
          chunkStartOffset = currentOffset;
        }
        currentBuffer.write(para);
        currentOffset += para.length;
      } else {
        if (currentBuffer.isNotEmpty) {
          chunks.add(
            TextChunk(
              text: currentBuffer.toString(),
              separator: '',
              originalOffset: chunkStartOffset,
            ),
          );
          currentBuffer.clear();
        }

        if (para.length <= maxChunkChars) {
          chunkStartOffset = currentOffset;
          currentBuffer.write(para);
          currentOffset += para.length;
        } else {
          // If a single paragraph is larger than maxChunkChars, split by sentence
          final sentences = _splitSentences(para);
          for (final sentence in sentences) {
            if (currentBuffer.length + sentence.length <= maxChunkChars) {
              if (currentBuffer.isEmpty) {
                chunkStartOffset = currentOffset;
              }
              currentBuffer.write(sentence);
              currentOffset += sentence.length;
            } else {
              if (currentBuffer.isNotEmpty) {
                chunks.add(
                  TextChunk(
                    text: currentBuffer.toString(),
                    separator: '',
                    originalOffset: chunkStartOffset,
                  ),
                );
                currentBuffer.clear();
              }
              chunkStartOffset = currentOffset;
              currentBuffer.write(sentence);
              currentOffset += sentence.length;
            }
          }
        }
      }
    }

    if (currentBuffer.isNotEmpty) {
      chunks.add(
        TextChunk(
          text: currentBuffer.toString(),
          separator: '',
          originalOffset: chunkStartOffset,
        ),
      );
    }

    return chunks;
  }

  List<String> _splitSentences(String text) {
    // Regex splits after sentence-ending punctuation followed by whitespace,
    // avoiding splits on decimals (e.g. 3.14) or URLs (e.g. mogate.tech)
    final pattern = RegExp(r'(?<=[.!?؟])\s+(?=[A-Z\p{L}])', unicode: true);
    return text.split(pattern);
  }

  String reassemble(List<String> correctedChunks, List<TextChunk> originalChunks) {
    if (correctedChunks.length != originalChunks.length) {
      return correctedChunks.join();
    }
    final buffer = StringBuffer();
    for (var i = 0; i < correctedChunks.length; i++) {
      buffer.write(correctedChunks[i]);
      buffer.write(originalChunks[i].separator);
    }
    return buffer.toString();
  }
}
