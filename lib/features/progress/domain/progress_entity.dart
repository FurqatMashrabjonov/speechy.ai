class UserProgress {
  final int totalXp;
  final int level;
  final String levelTitle;
  final int streak;
  final int longestStreak;
  final int totalSessions;
  final int totalMinutes;
  final DateTime? lastSessionDate;
  final List<String> badges;
  final List<SessionRecord> sessionHistory;
  final int streakFreezes;
  final DateTime? lastFreezeDate;

  const UserProgress({
    this.totalXp = 0,
    this.level = 1,
    this.levelTitle = 'Beginner',
    this.streak = 0,
    this.longestStreak = 0,
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.lastSessionDate,
    this.badges = const [],
    this.sessionHistory = const [],
    this.streakFreezes = 0,
    this.lastFreezeDate,
  });

  UserProgress copyWith({
    int? totalXp,
    int? level,
    String? levelTitle,
    int? streak,
    int? longestStreak,
    int? totalSessions,
    int? totalMinutes,
    DateTime? lastSessionDate,
    List<String>? badges,
    List<SessionRecord>? sessionHistory,
    int? streakFreezes,
    DateTime? lastFreezeDate,
  }) {
    return UserProgress(
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      badges: badges ?? this.badges,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      lastFreezeDate: lastFreezeDate ?? this.lastFreezeDate,
    );
  }

  int get avgScore {
    if (sessionHistory.isEmpty) return 0;
    final sum = sessionHistory.fold(0, (acc, s) => acc + s.overallScore);
    return (sum / sessionHistory.length).round();
  }

  int get xpForNextLevel => _xpThresholds[level] ?? 99999;
  int get xpForCurrentLevel => level > 1 ? (_xpThresholds[level - 1] ?? 0) : 0;
  double get levelProgress {
    final needed = xpForNextLevel - xpForCurrentLevel;
    if (needed <= 0) return 1.0;
    return ((totalXp - xpForCurrentLevel) / needed).clamp(0.0, 1.0);
  }

  static const _xpThresholds = {
    1: 100,
    2: 300,
    3: 600,
    4: 1000,
    5: 1500,
    6: 2200,
    7: 3000,
    8: 4000,
    9: 5500,
  };

  static const _levelTitles = {
    1: 'Beginner',
    2: 'Novice',
    3: 'Apprentice',
    4: 'Intermediate',
    5: 'Skilled',
    6: 'Advanced',
    7: 'Expert',
    8: 'Mentor',
    9: 'Virtuoso',
    10: 'Master Orator',
  };

  static (int, String) calculateLevel(int xp) {
    int level = 1;
    for (final entry in _xpThresholds.entries) {
      if (xp >= entry.value) {
        level = entry.key + 1;
      } else {
        break;
      }
    }
    if (level > 10) level = 10;
    return (level, _levelTitles[level] ?? 'Master Orator');
  }

  Map<String, dynamic> toMap() {
    return {
      'totalXp': totalXp,
      'level': level,
      'levelTitle': levelTitle,
      'streak': streak,
      'longestStreak': longestStreak,
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'badges': badges,
      'sessionHistory': sessionHistory.map((s) => s.toMap()).toList(),
      'streakFreezes': streakFreezes,
      'lastFreezeDate': lastFreezeDate?.toIso8601String(),
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      levelTitle: map['levelTitle'] as String? ?? 'Beginner',
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
      totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
      lastSessionDate: map['lastSessionDate'] != null
          ? DateTime.parse(map['lastSessionDate'] as String)
          : null,
      badges: List<String>.from(map['badges'] as List? ?? []),
      sessionHistory: (map['sessionHistory'] as List? ?? [])
          .map((s) => SessionRecord.fromMap(s as Map<String, dynamic>))
          .toList(),
      streakFreezes: (map['streakFreezes'] as num?)?.toInt() ?? 0,
      lastFreezeDate: map['lastFreezeDate'] != null
          ? DateTime.parse(map['lastFreezeDate'] as String)
          : null,
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
  final int xpEarned;
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
    required this.xpEarned,
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
      'xpEarned': xpEarned,
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
      xpEarned: (map['xpEarned'] as num?)?.toInt() ?? 0,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
    );
  }
}
