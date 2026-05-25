class HedgingDetector {
  static const _phrases = [
    'i think',
    'i believe',
    'i guess',
    'i suppose',
    'i feel like',
    'i might',
    'maybe',
    'perhaps',
    'probably',
    'possibly',
    'kind of',
    'sort of',
    "i'm not sure",
    'not sure if',
    'i could be wrong',
  ];

  static Map<String, int> detect(String transcript) {
    final result = <String, int>{};
    final userText = transcript
        .split('\n')
        .where((l) => l.startsWith('User:') || l.startsWith('You:'))
        .map((l) => l.replaceFirst(RegExp(r'^(User:|You:)\s*'), '').toLowerCase())
        .join(' ');

    for (final phrase in _phrases) {
      int count = 0;
      int idx = 0;
      while (true) {
        idx = userText.indexOf(phrase, idx);
        if (idx == -1) break;
        count++;
        idx += phrase.length;
      }
      if (count > 0) result[phrase] = count;
    }
    return result;
  }

  static int totalCount(Map<String, int> detected) =>
      detected.values.fold(0, (a, b) => a + b);
}
