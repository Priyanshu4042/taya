class TextPreprocessor {
  /// Cleans raw SMS or Email text while preserving all useful information.
  static String preprocess(String input) {
    if (input.trim().isEmpty) return "";

    String text = input;

    // ------------------------------------------------------------------
    // 1. Normalize line endings
    // ------------------------------------------------------------------
    text = text.replaceAll('\r\n', '\n');
    text = text.replaceAll('\r', '\n');

    // ------------------------------------------------------------------
    // 2. Decode common HTML entities
    // ------------------------------------------------------------------
    const htmlEntities = {
      '&nbsp;': ' ',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
    };

    htmlEntities.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    // ------------------------------------------------------------------
    // 3. Remove HTML tags
    // (keeps inner text)
    // ------------------------------------------------------------------
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // ------------------------------------------------------------------
    // 4. Normalize unicode punctuation
    // ------------------------------------------------------------------
    text = text
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('…', '...');

    // ------------------------------------------------------------------
    // 5. Remove invisible unicode characters
    // ------------------------------------------------------------------
    text = text.replaceAll(
      RegExp(r'[\u200B-\u200D\uFEFF\u2060]'),
      '',
    );

    // ------------------------------------------------------------------
    // 6. Replace tabs with spaces
    // ------------------------------------------------------------------
    text = text.replaceAll('\t', ' ');

    // ------------------------------------------------------------------
    // 7. Remove spaces before newline
    // ------------------------------------------------------------------
    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');

    // ------------------------------------------------------------------
    // 8. Collapse multiple spaces
    // ------------------------------------------------------------------
    text = text.replaceAll(RegExp(r' {2,}'), ' ');

    // ------------------------------------------------------------------
    // 9. Collapse excessive blank lines
    // ------------------------------------------------------------------
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // ------------------------------------------------------------------
    // 10. Remove common email footer separators
    // ------------------------------------------------------------------
    text = text.replaceAll(
      RegExp(r'^\s*-{5,}\s*$', multiLine: true),
      '',
    );

    // ------------------------------------------------------------------
    // 11. Remove quoted reply markers
    // Keeps only the latest email.
    // ------------------------------------------------------------------
    final quotePatterns = [
      RegExp(r'^On .* wrote:$', multiLine: true),
      RegExp(r'^From: .*$', multiLine: true),
      RegExp(r'^Sent: .*$', multiLine: true),
      RegExp(r'^-----Original Message-----$', multiLine: true),
    ];

    for (final pattern in quotePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        text = text.substring(0, match.start);
        break;
      }
    }

    // ------------------------------------------------------------------
    // 12. Trim every line
    // ------------------------------------------------------------------
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    text = lines.join('\n');

    return text.trim();
  }
}