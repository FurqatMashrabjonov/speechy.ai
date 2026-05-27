import 'package:speech_coach/features/progress/domain/progress_entity.dart';

String getSpeechyComment(double avgScore) {
  if (avgScore >= 85) {
    return '"You\'re crushing it! Your speaking skills are exceptional."';
  }
  if (avgScore >= 70) {
    return '"Great progress! Your consistency is really paying off."';
  }
  return '"Every practice session makes you better. Keep going!"';
}

String getMetricDescription(String metric, UserProgress progress) {
  final sessions = progress.sessionHistory;
  if (sessions.isEmpty) return 'No data yet';

  switch (metric) {
    case 'confidence':
      final avg =
          sessions.map((s) => s.confidence).reduce((a, b) => a + b) /
              sessions.length;
      return avg >= 75 ? 'Strong projection' : 'Building confidence';
    case 'clarity':
      final clarityAvg =
          sessions.map((s) => s.clarity).reduce((a, b) => a + b) /
              sessions.length;
      return clarityAvg >= 75 ? 'Clear communicator' : 'Building clarity';
    case 'emotion':
      final avg =
          sessions.map((s) => s.engagement).reduce((a, b) => a + b) /
              sessions.length;
      return avg >= 75 ? 'Warm & Engaging' : 'Building warmth';
    default:
      return '';
  }
}

String getMetricLevel(String metric, UserProgress progress) {
  final sessions = progress.sessionHistory;
  if (sessions.isEmpty) return '--';

  double avg;
  switch (metric) {
    case 'confidence':
      avg = sessions.map((s) => s.confidence).reduce((a, b) => a + b) /
          sessions.length;
      break;
    case 'emotion':
      avg = sessions.map((s) => s.engagement).reduce((a, b) => a + b) /
          sessions.length;
      break;
    default:
      return '--';
  }
  if (avg >= 80) return 'High';
  if (avg >= 60) return 'Medium';
  return 'Building';
}

String getMetricValue(String metric, UserProgress progress) {
  final sessions = progress.sessionHistory;
  if (sessions.isEmpty) return '--';

  switch (metric) {
    case 'clarity':
      final avg =
          sessions.map((s) => s.clarity).reduce((a, b) => a + b) /
              sessions.length;
      return '${avg.round()}%';
    default:
      return '--';
  }
}
