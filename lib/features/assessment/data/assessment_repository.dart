import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/assessment_entity.dart';
import '../domain/learning_plan_entity.dart';

class AssessmentRepository {
  static const _assessmentKey = 'assessment_result';
  static const _planKey = 'learning_plan';
  final SharedPreferences _prefs;

  AssessmentRepository(this._prefs);

  bool hasCompletedAssessment() {
    return _prefs.getString(_assessmentKey) != null;
  }

  AssessmentResult? getAssessmentResult() {
    final json = _prefs.getString(_assessmentKey);
    if (json == null) return null;
    try {
      return AssessmentResult.fromMap(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAssessmentResult(AssessmentResult result) async {
    await _prefs.setString(_assessmentKey, jsonEncode(result.toMap()));
  }

  LearningPlan? getLearningPlan() {
    final json = _prefs.getString(_planKey);
    if (json == null) return null;
    try {
      return LearningPlan.fromMap(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLearningPlan(LearningPlan plan) async {
    await _prefs.setString(_planKey, jsonEncode(plan.toMap()));
  }

  Future<void> markStepCompleted(String scenarioId, double score) async {
    final plan = getLearningPlan();
    if (plan == null) return;

    final updatedSteps = plan.steps.map((step) {
      if (step.scenarioId == scenarioId && !step.isCompleted) {
        return step.markCompleted(score);
      }
      return step;
    }).toList();

    await saveLearningPlan(plan.copyWith(steps: updatedSteps));
  }

  Future<void> incrementRetryCount(String scenarioId) async {
    final plan = getLearningPlan();
    if (plan == null) return;
    final updatedSteps = plan.steps.map((step) {
      if (step.scenarioId == scenarioId && !step.isCompleted) {
        return step.incrementRetry();
      }
      return step;
    }).toList();
    await saveLearningPlan(plan.copyWith(steps: updatedSteps));
  }
}
