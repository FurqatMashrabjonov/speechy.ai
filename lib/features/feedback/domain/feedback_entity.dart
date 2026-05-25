class ConversationFeedback {
  final int clarity;
  final int confidence;
  final int engagement;
  final int relevance;
  final int overallScore;
  final String summary;
  final List<String> strengths;
  final List<String> improvements;
  final DateTime createdAt;
  final String scenarioId;
  final String category;
  final int durationSeconds;
  // Coaching focus fields (v2)
  final String? focusPriority;
  final String? focusChallenge;
  final String? transcriptMoment;

  const ConversationFeedback({
    required this.clarity,
    required this.confidence,
    required this.engagement,
    required this.relevance,
    required this.overallScore,
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.createdAt,
    required this.scenarioId,
    required this.category,
    required this.durationSeconds,
    this.focusPriority,
    this.focusChallenge,
    this.transcriptMoment,
  });

  factory ConversationFeedback.fromMap(Map<String, dynamic> map) {
    return ConversationFeedback(
      clarity: (map['clarity'] as num).toInt(),
      confidence: (map['confidence'] as num).toInt(),
      engagement: (map['engagement'] as num).toInt(),
      relevance: (map['relevance'] as num).toInt(),
      overallScore: (map['overallScore'] as num).toInt(),
      summary: map['summary'] as String? ?? '',
      strengths: List<String>.from(map['strengths'] as List? ?? []),
      improvements: List<String>.from(map['improvements'] as List? ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      scenarioId: map['scenarioId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      focusPriority: map['focusPriority'] as String?,
      focusChallenge: map['focusChallenge'] as String?,
      transcriptMoment: map['transcriptMoment'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clarity': clarity,
      'confidence': confidence,
      'engagement': engagement,
      'relevance': relevance,
      'overallScore': overallScore,
      'summary': summary,
      'strengths': strengths,
      'improvements': improvements,
      'createdAt': createdAt.toIso8601String(),
      'scenarioId': scenarioId,
      'category': category,
      'durationSeconds': durationSeconds,
      if (focusPriority != null) 'focusPriority': focusPriority,
      if (focusChallenge != null) 'focusChallenge': focusChallenge,
      if (transcriptMoment != null) 'transcriptMoment': transcriptMoment,
    };
  }
}
