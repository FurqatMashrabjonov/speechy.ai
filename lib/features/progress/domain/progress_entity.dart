class UserProgress {
  final int totalSessions;
  final int totalMinutes;
  final DateTime? lastSessionDate;
  final List<String> badges;
  final List<SessionRecord> sessionHistory;

  const UserProgress({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.lastSessionDate,
    this.badges = const [],
    this.sessionHistory = const [],
  });

  UserProgress copyWith({
    int? totalSessions,
    int? totalMinutes,
    DateTime? lastSessionDate,
    List<String>? badges,
    List<SessionRecord>? sessionHistory,
  }) {
    return UserProgress(
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      badges: badges ?? this.badges,
      sessionHistory: sessionHistory ?? this.sessionHistory,
    );
  }

  int get avgScore {
    if (sessionHistory.isEmpty) return 0;
    final sum = sessionHistory.fold(0, (acc, s) => acc + s.overallScore);
    return (sum / sessionHistory.length).round();
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'badges': badges,
      'sessionHistory': sessionHistory.map((s) => s.toMap()).toList(),
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
      totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
      lastSessionDate: map['lastSessionDate'] != null
          ? DateTime.tryParse(map['lastSessionDate'] as String)
          : null,
      badges: List<String>.from(map['badges'] as List? ?? []),
      sessionHistory: (map['sessionHistory'] as List? ?? [])
          .map((s) => SessionRecord.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SessionRecord {
  final String scenarioId;
  final String category;
  final int overallScore;
  final int clarity;
  final int confidence;
  final int engagement;
  final int relevance;
  final int durationSeconds;
  final DateTime date;

  const SessionRecord({
    required this.scenarioId,
    required this.category,
    required this.overallScore,
    required this.clarity,
    required this.confidence,
    required this.engagement,
    required this.relevance,
    required this.durationSeconds,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'scenarioId': scenarioId,
      'category': category,
      'overallScore': overallScore,
      'clarity': clarity,
      'confidence': confidence,
      'engagement': engagement,
      'relevance': relevance,
      'durationSeconds': durationSeconds,
      'date': date.toIso8601String(),
    };
  }

  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      scenarioId: map['scenarioId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      overallScore: (map['overallScore'] as num?)?.toInt() ?? 0,
      clarity: (map['clarity'] as num?)?.toInt() ?? 0,
      confidence: (map['confidence'] as num?)?.toInt() ?? 0,
      engagement: (map['engagement'] as num?)?.toInt() ?? 0,
      relevance: (map['relevance'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
