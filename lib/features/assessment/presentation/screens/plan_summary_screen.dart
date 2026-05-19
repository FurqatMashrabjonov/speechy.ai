import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/scenarios/data/scenario_repository.dart';
import 'package:speech_coach/features/scenarios/domain/scenario_entity.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/progress_bar.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import '../../domain/learning_plan_entity.dart';
import '../providers/assessment_provider.dart';

class PlanSummaryScreen extends ConsumerWidget {
  const PlanSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(learningPlanProvider);

    if (plan == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No plan found', style: AppTypography.headlineSmall()),
              const SizedBox(height: 16),
              DuoButton.primary(
                text: 'Go Home',
                onTap: () {
                  ref.invalidate(hasAssessmentProvider);
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      );
    }

    final repo = ScenarioRepository();
    final nextStep = plan.nextStep;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Tappable(
                    onTap: () {
                      ref.invalidate(hasAssessmentProvider);
                      context.go('/home');
                    },
                    child: const Icon(Icons.close_rounded, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    'Your Learning Plan',
                    style: AppTypography.titleMedium(),
                  ),
                  const Spacer(),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Plan header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.primary.withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.route_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.title,
                                      style: AppTypography.headlineSmall(),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${plan.totalSteps} lessons',
                                      style: AppTypography.labelSmall(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            plan.description,
                            style: AppTypography.bodySmall(
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Event date + sessions/day
                          if (plan.eventDate != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: plan.isIntensiveMode
                                    ? AppColors.error.withValues(alpha: 0.08)
                                    : AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: plan.isIntensiveMode
                                      ? AppColors.error.withValues(alpha: 0.25)
                                      : AppColors.primary
                                          .withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    plan.isIntensiveMode
                                        ? Icons.local_fire_department_rounded
                                        : Icons.event_rounded,
                                    size: 16,
                                    color: plan.isIntensiveMode
                                        ? AppColors.error
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      plan.isIntensiveMode
                                          ? '${plan.daysUntilEvent} days left — intensive mode active'
                                          : '${plan.daysUntilEvent} days to your event',
                                      style: AppTypography.labelSmall(
                                        color: plan.isIntensiveMode
                                            ? AppColors.error
                                            : AppColors.primary,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: plan.isIntensiveMode
                                          ? AppColors.error
                                              .withValues(alpha: 0.12)
                                          : AppColors.primary
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${plan.sessionsPerDayTarget}×/day',
                                      style: AppTypography.labelSmall(
                                        color: plan.isIntensiveMode
                                            ? AppColors.error
                                            : AppColors.primary,
                                      ).copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Row(
                            children: [
                              Expanded(
                                child: ProgressBar(
                                  value: plan.progressPercent,
                                  height: 10,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${plan.completedCount}/${plan.totalSteps}',
                                style: AppTypography.labelMedium(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                    const SizedBox(height: 24),

                    // Steps header
                    Text(
                      'Your personalized path',
                      style: AppTypography.headlineSmall(),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 16),

                    // Step list
                    ...plan.steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      final scenario = repo.getById(step.scenarioId);
                      final isNext = nextStep?.scenarioId == step.scenarioId;

                      return _PlanStepCard(
                        step: step,
                        scenario: scenario,
                        stepNumber: index + 1,
                        isNext: isNext,
                        isLast: index == plan.steps.length - 1,
                      )
                          .animate()
                          .fadeIn(
                            delay: (300 + index * 80).ms,
                            duration: 400.ms,
                          )
                          .slideX(begin: 0.03);
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: context.divider,
                    width: 1,
                  ),
                ),
              ),
              child: DuoButton.primary(
                text: nextStep != null ? 'Start First Lesson' : 'Go Home',
                icon: nextStep != null
                    ? Icons.play_arrow_rounded
                    : Icons.home_rounded,
                width: double.infinity,
                onTap: () {
                  ref.invalidate(hasAssessmentProvider);
                  if (nextStep != null) {
                    context.push(
                      '/scenario/${Uri.encodeComponent(nextStep.scenarioId)}',
                    );
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanStepCard extends StatelessWidget {
  final PlanStep step;
  final Scenario? scenario;
  final int stepNumber;
  final bool isNext;
  final bool isLast;

  const _PlanStepCard({
    required this.step,
    required this.scenario,
    required this.stepNumber,
    required this.isNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    if (scenario == null) return const SizedBox.shrink();

    return Tappable(
      onTap: () {
        context.push(
          '/scenario/${Uri.encodeComponent(step.scenarioId)}',
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: step.isCompleted
                      ? AppColors.success
                      : isNext
                          ? AppColors.primary
                          : const Color(0xFFE5E5E5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: step.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.white,
                          size: 20,
                        )
                      : Text(
                          '$stepNumber',
                          style: AppTypography.labelMedium(
                            color: isNext
                                ? AppColors.white
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 48,
                  color: step.isCompleted
                      ? AppColors.success.withValues(alpha: 0.3)
                      : const Color(0xFFE5E5E5),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Card content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isNext
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isNext
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : const Color(0xFFE5E5E5),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scenario!.categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      scenario!.categoryIcon,
                      color: scenario!.categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario!.title,
                          style: AppTypography.titleMedium(
                            color: step.isCompleted
                                ? context.textSecondary
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              scenario!.category,
                              style: AppTypography.labelSmall(
                                color: scenario!.categoryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _difficultyColor(scenario!.difficulty)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                scenario!.difficulty,
                                style: AppTypography.labelSmall(
                                  color:
                                      _difficultyColor(scenario!.difficulty),
                                ).copyWith(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (step.isCompleted && step.score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${step.score!.round()}%',
                        style: AppTypography.labelMedium(
                          color: AppColors.success,
                        ),
                      ),
                    )
                  else if (isNext)
                    Icon(
                      Icons.play_circle_filled_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return AppColors.success;
      case 'Medium':
        return AppColors.warning;
      case 'Hard':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
