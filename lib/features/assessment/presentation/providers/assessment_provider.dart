import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speech_coach/shared/providers/user_provider.dart';
import '../../data/assessment_data.dart';
import '../../data/assessment_repository.dart';
import '../../domain/assessment_entity.dart';
import '../../domain/learning_plan_entity.dart';

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return AssessmentRepository(prefs);
});

final hasAssessmentProvider = Provider<bool>((ref) {
  final repo = ref.read(assessmentRepositoryProvider);
  return repo.hasCompletedAssessment();
});

final learningPlanProvider =
    StateNotifierProvider<LearningPlanNotifier, LearningPlan?>((ref) {
  final repo = ref.read(assessmentRepositoryProvider);
  return LearningPlanNotifier(repo);
});

class LearningPlanNotifier extends StateNotifier<LearningPlan?> {
  final AssessmentRepository _repo;

  LearningPlanNotifier(this._repo) : super(null) {
    _load();
  }

  void _load() {
    state = _repo.getLearningPlan();
  }

  Future<void> generateFromAssessment(List<AssessmentAnswer> answers) async {
    final templateId = matchTemplate(answers);
    final result = AssessmentResult(
      answers: answers,
      templateId: templateId,
      completedAt: DateTime.now(),
    );

    await _repo.saveAssessmentResult(result);

    final plan = generatePlan(result);
    await _repo.saveLearningPlan(plan);
    state = plan;
  }

  Future<ChainResult> markCompleted(String scenarioId, double score) async {
    if (state == null) return ChainResult.needsRetry;
    final step = state!.steps.cast<PlanStep?>().firstWhere(
          (s) => s?.scenarioId == scenarioId,
          orElse: () => null,
        );
    final passed = score >= (step?.minPassScore ?? 60);
    if (!passed) {
      await _repo.incrementRetryCount(scenarioId);
    }
    await _repo.markStepCompleted(scenarioId, score);
    state = _repo.getLearningPlan();
    return passed ? ChainResult.passed : ChainResult.needsRetry;
  }

  Future<void> unlockNextLevel() async {
    if (state == null || !state!.isComplete) return;
    final nextLevel = state!.chainLevel + 1;
    final upgraded = state!.copyWith(
      steps: state!.steps
          .map((s) => PlanStep(
                scenarioId: s.scenarioId,
                order: s.order,
                minPassScore: (s.minPassScore + 10).clamp(0, 95),
                difficulty: _upgradeDifficulty(s.difficulty),
                retryCount: 0,
              ))
          .toList(),
      chainLevel: nextLevel,
    );
    await _repo.saveLearningPlan(upgraded);
    state = upgraded;
  }

  String _upgradeDifficulty(String d) {
    if (d == 'easy') return 'medium';
    if (d == 'medium') return 'hard';
    return 'hard';
  }

  Future<void> switchRoadmap(String templateId) async {
    final plan = generatePlanFromTemplateId(templateId);
    await _repo.saveLearningPlan(plan);
    await _repo.saveAssessmentResult(AssessmentResult(
      answers: const [],
      templateId: templateId,
      completedAt: DateTime.now(),
    ));
    state = plan;
  }

  PlanStep? get nextStep => state?.nextStep;
}
