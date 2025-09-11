class LinkExtractor {
  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  static List<String> extractLinks(String text) {
    final matches = _urlRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  static bool containsLinks(String text) {
    return _urlRegex.hasMatch(text);
  }
}