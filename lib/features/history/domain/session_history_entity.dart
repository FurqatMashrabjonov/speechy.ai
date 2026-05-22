class SessionHistoryEntry {
  final String id;
  final String scenarioId;
  final String scenarioTitle;
  final String category;
  final int? overallScore;
  final int? clarity;
  final int? confidence;
  final int? engagement;
  final int? relevance;
  final String? summary;
  final List<String>? strengths;
  final List<String>? improvements;
  final String transcript;
  final int durationSeconds;
  final DateTime createdAt;
  final String feedbackStatus; // "pending" | "completed" | "failed"
  final String scenarioPrompt;
  final String? feedbackGeneratedBy; // "client" | "cloud_function"

  const SessionHistoryEntry({
    required this.id,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.category,
    this.overallScore,
    this.clarity,
    this.confidence,
    this.engagement,
    this.relevance,
    this.summary,
    this.strengths,
    this.improvements,
    required this.transcript,
    required this.durationSeconds,
    required this.createdAt,
    this.feedbackStatus = 'completed',
    this.scenarioPrompt = '',
    this.feedbackGeneratedBy,
  });

  bool get isPending => feedbackStatus == 'pending';
  bool get isCompleted => feedbackStatus == 'completed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scenarioId': scenarioId,
      'scenarioTitle': scenarioTitle,
      'category': category,
      'overallScore': overallScore,
      'clarity': clarity,
      'confidence': confidence,
      'engagement': engagement,
      'relevance': relevance,
      'summary': summary,
      'strengths': strengths,
      'improvements': improvements,
      'transcript': transcript,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
      'feedbackStatus': feedbackStatus,
      'scenarioPrompt': scenarioPrompt,
      if (feedbackGeneratedBy != null)
        'feedbackGeneratedBy': feedbackGeneratedBy,
    };
  }

  factory SessionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SessionHistoryEntry(
      id: map['id'] as String? ?? '',
      scenarioId: map['scenarioId'] as String? ?? '',
      scenarioTitle: map['scenarioTitle'] as String? ?? '',
      category: map['category'] as String? ?? '',
      overallScore: (map['overallScore'] as num?)?.toInt(),
      clarity: (map['clarity'] as num?)?.toInt(),
      confidence: (map['confidence'] as num?)?.toInt(),
      engagement: (map['engagement'] as num?)?.toInt(),
      relevance: (map['relevance'] as num?)?.toInt(),
      summary: map['summary'] as String?,
      strengths: map['strengths'] != null
          ? List<String>.from(map['strengths'] as List)
          : null,
      improvements: map['improvements'] != null
          ? List<String>.from(map['improvements'] as List)
          : null,
      transcript: map['transcript'] as String? ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      feedbackStatus: map['feedbackStatus'] as String? ?? 'completed',
      scenarioPrompt: map['scenarioPrompt'] as String? ?? '',
      feedbackGeneratedBy: map['feedbackGeneratedBy'] as String?,
    );
  }

  SessionHistoryEntry copyWith({
    int? overallScore,
    int? clarity,
    int? confidence,
    int? engagement,
    int? relevance,
    String? summary,
    List<String>? strengths,
    List<String>? improvements,
    String? feedbackStatus,
    String? feedbackGeneratedBy,
  }) {
    return SessionHistoryEntry(
      id: id,
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      category: category,
      overallScore: overallScore ?? this.overallScore,
      clarity: clarity ?? this.clarity,
      confidence: confidence ?? this.confidence,
      engagement: engagement ?? this.engagement,
      relevance: relevance ?? this.relevance,
      summary: summary ?? this.summary,
      strengths: strengths ?? this.strengths,
      improvements: improvements ?? this.improvements,
      transcript: transcript,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      feedbackStatus: feedbackStatus ?? this.feedbackStatus,
      scenarioPrompt: scenarioPrompt,
      feedbackGeneratedBy: feedbackGeneratedBy ?? this.feedbackGeneratedBy,
    );
  }
}
