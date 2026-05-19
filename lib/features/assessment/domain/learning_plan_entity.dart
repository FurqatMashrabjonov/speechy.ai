enum ChainResult { passed, needsRetry }

class LearningPlan {
  final String templateId;
  final String title;
  final String description;
  final List<PlanStep> steps;
  final DateTime createdAt;
  final DateTime? eventDate;
  final int sessionsPerDayTarget;
  final int chainLevel;

  const LearningPlan({
    required this.templateId,
    required this.title,
    required this.description,
    required this.steps,
    required this.createdAt,
    this.eventDate,
    this.sessionsPerDayTarget = 1,
    this.chainLevel = 1,
  });

  int get completedCount => steps.where((s) => s.isCompleted).length;
  int get totalSteps => steps.length;
  double get progressPercent =>
      totalSteps == 0 ? 0 : completedCount / totalSteps;
  bool get isComplete => completedCount == totalSteps;

  int get daysUntilEvent =>
      eventDate?.difference(DateTime.now()).inDays ?? 999;
  bool get isIntensiveMode => daysUntilEvent <= 7 && daysUntilEvent >= 0;

  PlanStep? get nextStep {
    try {
      return steps.firstWhere((s) => !s.isCompleted);
    } catch (_) {
      return null;
    }
  }

  LearningPlan copyWith({
    List<PlanStep>? steps,
    DateTime? eventDate,
    int? sessionsPerDayTarget,
    int? chainLevel,
  }) =>
      LearningPlan(
        templateId: templateId,
        title: title,
        description: description,
        steps: steps ?? this.steps,
        createdAt: createdAt,
        eventDate: eventDate ?? this.eventDate,
        sessionsPerDayTarget:
            sessionsPerDayTarget ?? this.sessionsPerDayTarget,
        chainLevel: chainLevel ?? this.chainLevel,
      );

  Map<String, dynamic> toMap() => {
        'templateId': templateId,
        'title': title,
        'description': description,
        'steps': steps.map((s) => s.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'eventDate': eventDate?.toIso8601String(),
        'sessionsPerDayTarget': sessionsPerDayTarget,
        'chainLevel': chainLevel,
      };

  factory LearningPlan.fromMap(Map<String, dynamic> map) => LearningPlan(
        templateId: map['templateId'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        steps: (map['steps'] as List)
            .map((s) => PlanStep.fromMap(s as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        eventDate: map['eventDate'] != null
            ? DateTime.parse(map['eventDate'] as String)
            : null,
        sessionsPerDayTarget:
            (map['sessionsPerDayTarget'] as num?)?.toInt() ?? 1,
        chainLevel: (map['chainLevel'] as num?)?.toInt() ?? 1,
      );
}

class PlanStep {
  final String scenarioId;
  final int order;
  final bool isCompleted;
  final double? score;
  final int minPassScore;
  final String difficulty;
  final int retryCount;

  const PlanStep({
    required this.scenarioId,
    required this.order,
    this.isCompleted = false,
    this.score,
    this.minPassScore = 60,
    this.difficulty = 'medium',
    this.retryCount = 0,
  });

  bool get isPassed => isCompleted && (score ?? 0) >= minPassScore;

  PlanStep markCompleted(double score) => PlanStep(
        scenarioId: scenarioId,
        order: order,
        isCompleted: true,
        score: score,
        minPassScore: minPassScore,
        difficulty: difficulty,
        retryCount: retryCount,
      );

  PlanStep incrementRetry() => PlanStep(
        scenarioId: scenarioId,
        order: order,
        isCompleted: isCompleted,
        score: score,
        minPassScore: minPassScore,
        difficulty: difficulty,
        retryCount: retryCount + 1,
      );

  Map<String, dynamic> toMap() => {
        'scenarioId': scenarioId,
        'order': order,
        'isCompleted': isCompleted,
        'score': score,
        'minPassScore': minPassScore,
        'difficulty': difficulty,
        'retryCount': retryCount,
      };

  factory PlanStep.fromMap(Map<String, dynamic> map) => PlanStep(
        scenarioId: map['scenarioId'] as String,
        order: map['order'] as int,
        isCompleted: map['isCompleted'] as bool? ?? false,
        score: (map['score'] as num?)?.toDouble(),
        minPassScore: (map['minPassScore'] as num?)?.toInt() ?? 60,
        difficulty: map['difficulty'] as String? ?? 'medium',
        retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      );
}
