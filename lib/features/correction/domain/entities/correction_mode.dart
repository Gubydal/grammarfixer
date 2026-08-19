/// Correction modes supported by GrammarFix
enum CorrectionMode {
  correct('Correct', 'Fixes grammar, spelling, and punctuation errors with minimal changes.'),
  improve('Improve', 'Polishes phrasing, enhances clarity, and suggests style improvements.');

  final String label;
  final String description;

  const CorrectionMode(this.label, this.description);

  static CorrectionMode fromString(String val) {
    if (val.toLowerCase() == 'improve') {
      return CorrectionMode.improve;
    }
    return CorrectionMode.correct;
  }
}
