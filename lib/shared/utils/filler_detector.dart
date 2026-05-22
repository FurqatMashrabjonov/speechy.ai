class FillerDetector {
  static const _fillerWords = [
    'um', 'uh', 'like', 'you know', 'basically',
    'actually', 'literally', 'right', 'so', 'er', 'ah',
  ];

  static final _patterns = _fillerWords.map((word) {
    final escaped = RegExp.escape(word);
    return MapEntry(word, RegExp('\\b$escaped\\b', caseSensitive: false));
  }).toList();

  static Map<String, int> detect(String text) {
    final result = <String, int>{};
    for (final entry in _patterns) {
      final count = entry.value.allMatches(text).length;
      if (count > 0) result[entry.key] = count;
    }
    return result;
  }

  static int totalCount(String text) =>
      detect(text).values.fold(0, (sum, count) => sum + count);
}
