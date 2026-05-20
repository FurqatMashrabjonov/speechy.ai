import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speech_coach/shared/providers/user_provider.dart';
import '../../data/assessment_data.dart';
import '../../data/assessment_repository.dart';
import '../../data/plan_remote_repository.dart';
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
  final remote = ref.read(planRemoteRepositoryProvider);
  return LearningPlanNotifier(repo, remote);
});

class LearningPlanNotifier extends StateNotifier<LearningPlan?> {
  final AssessmentRepository _repo;
  final PlanRemoteRepository _remote;

  LearningPlanNotifier(this._repo, this._remote) : super(null) {
    _loadAndSync();
  }

  Future<void> _loadAndSync() async {
    // Load local first — always fast
    final local = _repo.getLearningPlan();
    state = local;

    // Sync with Firestore
    try {
      final remote = await _remote.load().timeout(const Duration(seconds: 5));
      final merged = PlanRemoteRepository.merge(local, remote);
      if (merged != null && merged != local) {
        await _repo.saveLearningPlan(merged);
        state = merged;
        debugPrint('LearningPlanNotifier: restored plan from Firestore');
      } else if (local != null && remote == null) {
        // Push local plan to cloud (first sync after install)
        _remote.save(local).catchError((_) {});
      }
    } catch (_) {
      // Offline — use local silently
    }
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
    _remote.save(plan).catchError((_) {});
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
    if (state != null) _remote.save(state!).catchError((_) {});
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
    _remote.save(upgraded).catchError((_) {});
  }

  String _upgradeDifficulty(String d) {
    if (d == 'easy') return 'medium';
    if (d == 'medium') return 'hard';
    return 'hard';
  }

  Future<void> generateForTemplate(
      String templateId, List<AssessmentAnswer> answers) async {
    final result = AssessmentResult(
      answers: answers,
      templateId: templateId,
      completedAt: DateTime.now(),
    );
    await _repo.saveAssessmentResult(result);
    final plan = generatePlan(result);
    await _repo.saveLearningPlan(plan);
    state = plan;
    _remote.save(plan).catchError((_) {});
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
    _remote.save(plan).catchError((_) {});
  }

  PlanStep? get nextStep => state?.nextStep;
}
