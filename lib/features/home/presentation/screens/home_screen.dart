import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/daily_goal/domain/daily_goal_entity.dart';
import 'package:speech_coach/features/daily_goal/presentation/providers/daily_goal_provider.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/progress_bar.dart';
import 'package:speech_coach/shared/widgets/skeleton.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/features/progress/domain/progress_entity.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/assessment/domain/learning_plan_entity.dart';
import 'package:speech_coach/features/scenarios/data/scenario_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

bool _isWrappedAvailable(UserProgress progress) {
  final now = DateTime.now();
  if (now.day > 7) return false;
  final lastMonth = now.month > 1
      ? DateTime(now.year, now.month - 1)
      : DateTime(now.year - 1, 12);
  return progress.sessionHistory.any(
      (s) => s.date.year == lastMonth.year && s.date.month == lastMonth.month);
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _wrappedShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowWrapped();
    });
  }

  void _maybeShowWrapped() {
    if (_wrappedShown) return;
    final progress = ref.read(progressProvider);
    if (_isWrappedAvailable(progress)) {
      _wrappedShown = true;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Monthly Wrapped Ready!',
                style: AppTypography.headlineSmall(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your voice recap for last month is ready.',
                style: AppTypography.bodySmall(
                  color: ctx.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/voice-wrapped');
              },
              child: const Text('View'),
            ),
          ],
        ),
      );
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _headingText(UserProgress progress, DailyGoal dailyGoal) {
    if (dailyGoal.completedToday >= dailyGoal.targetSessions) {
      return "You've hit your daily goal!";
    }
    if (progress.streak >= 7) {
      return '${progress.streak}-day streak! Keep going!';
    }
    if (progress.totalSessions == 0) {
      return 'Start your speaking journey';
    }
    return "Let's find your voice!";
  }

  String _subtitleText(UserProgress progress, DailyGoal dailyGoal) {
    if (dailyGoal.completedToday >= dailyGoal.targetSessions) {
      return 'Practice more to level up';
    }
    if (progress.streak > 0) {
      return 'Consistency is key to fluency';
    }
    if (progress.totalSessions == 0) {
      return 'Complete your first session today';
    }
    return 'Consistency is key to fluency';
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final dailyChallenge = ref.watch(dailyChallengeProvider);
    final authState = ref.watch(authStateProvider);
    final userName = authState.whenData((user) => user?.displayName).value;
    final firstName = (userName != null && userName.isNotEmpty)
        ? userName.split(' ').first
        : 'Speaker';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // --- Section 1: Header ---
              Row(
                children: [
                  // User avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting.toUpperCase(),
                          style: AppTypography.labelSmall(
                            color: context.textTertiary,
                          ).copyWith(
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          firstName,
                          style: AppTypography.headlineSmall(),
                        ),
                      ],
                    ),
                  ),
                  // Settings
                  Tappable(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: context.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),

              // --- Section 2: Heading ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headingText(progress, dailyGoal),
                    style: AppTypography.headlineMedium(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleText(progress, dailyGoal),
                    style: AppTypography.bodySmall(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 24),

              // --- Section 3: Daily Goal Card ---
              _DailyGoalCard(
                completedToday: dailyGoal.completedToday,
                target: dailyGoal.targetSessions,
                dailyChallenge: dailyChallenge,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 24),

              // --- Section: Learning Plan ---
              _LearningPlanSection(),
              const SizedBox(height: 24),

              // --- Section 4: Quick Start ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Start',
                    style: AppTypography.headlineSmall(),
                  ),
                  Tappable(
                    onTap: () => context.go('/practice'),
                    child: Text(
                      'View All',
                      style: AppTypography.labelMedium(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickStartCard(
                      title: 'Freestyle',
                      subtitle: 'Free practice',
                      icon: Icons.mic_rounded,
                      color: AppColors.cardPeach,
                      onTap: () => context.push(
                        '/conversation/${Uri.encodeComponent('Freestyle')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickStartCard(
                      title: 'Daily Lesson',
                      subtitle: 'Guided session',
                      icon: Icons.school_rounded,
                      color: AppColors.cardBlue,
                      onTap: () {
                        if (dailyChallenge != null) {
                          context.push(
                            '/scenario/${Uri.encodeComponent(dailyChallenge.id)}',
                          );
                        } else {
                          context.go('/practice');
                        }
                      },
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 24),

              // --- Section 5: Your Progress ---
              Text(
                'Your Progress',
                style: AppTypography.headlineSmall(),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.local_fire_department_rounded,
                        value: '${progress.streak}',
                        label: 'Streak',
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: context.divider,
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.chat_bubble_rounded,
                        value: '${progress.totalSessions}',
                        label: 'Sessions',
                        color: AppColors.skyBlue,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: context.divider,
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.star_rounded,
                        value: progress.sessionHistory.isNotEmpty
                            ? '${(progress.sessionHistory.map((s) => s.overallScore).reduce((a, b) => a + b) / progress.sessionHistory.length).round()}%'
                            : '--',
                        label: 'Accuracy',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final int completedToday;
  final int target;
  final dynamic dailyChallenge;

  const _DailyGoalCard({
    required this.completedToday,
    required this.target,
    this.dailyChallenge,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (completedToday / target).clamp(0.0, 1.0);
    final isComplete = completedToday >= target;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle_rounded : Icons.flag_rounded,
                color: isComplete ? AppColors.success : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Goal',
                style: AppTypography.titleMedium(),
              ),
              const Spacer(),
              Icon(
                isComplete ? Icons.emoji_events_rounded : Icons.flag_rounded,
                color: isComplete ? AppColors.gold : AppColors.primary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isComplete
                ? 'Great job! Goal completed!'
                : '${target - completedToday} session${target - completedToday > 1 ? "s" : ""} remaining',
            style: AppTypography.bodySmall(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ProgressBar(
            value: progress,
            height: 8,
            color: isComplete ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(height: 12),
          DuoButton.primary(
            text: isComplete ? 'Practice More' : 'Continue Practicing',
            width: double.infinity,
            onTap: () {
              if (dailyChallenge != null) {
                context.push(
                  '/scenario/${Uri.encodeComponent(dailyChallenge.id)}',
                );
              } else {
                context.push(
                  '/conversation/${Uri.encodeComponent('Freestyle')}',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickStartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.titleMedium()),
            Text(
              subtitle,
              style: AppTypography.labelSmall(
                color: context.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headlineMedium(color: color)
              .copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: AppTypography.labelSmall(
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LearningPlanSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(learningPlanProvider);
    if (plan == null) return const SizedBox.shrink();

    final nextStep = plan.nextStep;
    final repo = ScenarioRepository();
    final nextScenario =
        nextStep != null ? repo.getById(nextStep.scenarioId) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.title, style: AppTypography.headlineSmall()),
                if (plan.chainLevel > 1)
                  Text(
                    'Level ${plan.chainLevel}',
                    style: AppTypography.labelSmall(
                        color: AppColors.primary),
                  ),
              ],
            ),
            Tappable(
              onTap: () => context.push('/plan-summary'),
              child: Text(
                'See All',
                style:
                    AppTypography.labelMedium(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Intensive mode urgency banner
        if (plan.isIntensiveMode)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 6),
                Text(
                  '${plan.daysUntilEvent} days to your event — intensive mode',
                  style: AppTypography.labelSmall(color: AppColors.error)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress header
              Row(
                children: [
                  Text(
                    '${plan.completedCount}/${plan.totalSteps} steps',
                    style: AppTypography.labelMedium(
                        color: context.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '${(plan.progressPercent * 100).round()}%',
                    style: AppTypography.labelMedium(
                        color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ProgressBar(
                value: plan.progressPercent,
                height: 8,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),

              // Step nodes (horizontal scroll)
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: plan.steps.length,
                  separatorBuilder: (_, __) => _StepConnector(),
                  itemBuilder: (context, i) {
                    final step = plan.steps[i];
                    final isNext = nextStep?.scenarioId == step.scenarioId;
                    return _StepNode(
                      step: step,
                      index: i,
                      isNext: isNext,
                    );
                  },
                ),
              ),

              // Next step CTA
              if (nextScenario != null) ...[
                const SizedBox(height: 14),
                Tappable(
                  onTap: () => context.push(
                    '/scenario/${Uri.encodeComponent(nextStep?.scenarioId ?? '')}',
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_filled_rounded,
                            color: AppColors.primary, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Next Up',
                                    style: AppTypography.labelSmall(
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 6),
                                  _DifficultyChip(
                                      difficulty: nextStep?.difficulty ?? 'medium'),
                                ],
                              ),
                              Text(
                                nextScenario.title,
                                style: AppTypography.titleMedium(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: context.textTertiary, size: 20),
                      ],
                    ),
                  ),
                ),
              ],

              // Plan complete CTA
              if (plan.isComplete) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.success, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chain Complete!',
                                style: AppTypography.titleMedium(
                                    color: AppColors.success)),
                            Text('Ready for Level ${plan.chainLevel + 1}?',
                                style: AppTypography.bodySmall(
                                    color: context.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.05);
  }
}

class _StepNode extends StatelessWidget {
  final PlanStep step;
  final int index;
  final bool isNext;

  const _StepNode({
    required this.step,
    required this.index,
    required this.isNext,
  });

  Color _difficultyColor() {
    switch (step.difficulty) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = step.isCompleted
        ? AppColors.success
        : isNext
            ? AppColors.primary
            : const Color(0xFFD1D5DB);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: step.isCompleted
                ? AppColors.success.withValues(alpha: 0.12)
                : isNext
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isNext ? 2.5 : 1.5),
          ),
          child: Center(
            child: step.isCompleted
                ? const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 18)
                : isNext
                    ? const Icon(Icons.play_arrow_rounded,
                        color: AppColors.primary, size: 18)
                    : Text(
                        '${index + 1}',
                        style: AppTypography.labelSmall(
                            color: const Color(0xFF9CA3AF)),
                      ),
          ),
        ),
        const SizedBox(height: 4),
        if (step.isCompleted && step.score != null)
          Text(
            '${step.score!.round()}',
            style: AppTypography.labelSmall(color: AppColors.success)
                .copyWith(fontSize: 10),
          )
        else
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _difficultyColor(),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 17),
          Container(height: 1.5, color: const Color(0xFFE5E7EB)),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String difficulty;

  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = difficulty == 'easy'
        ? AppColors.success
        : difficulty == 'hard'
            ? AppColors.error
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty,
        style: AppTypography.labelSmall(color: color)
            .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              const SkeletonCircle(size: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 100, height: 12),
                  const SizedBox(height: 6),
                  const SkeletonLine(width: 80, height: 20),
                ],
              ),
              const Spacer(),
              const SkeletonCircle(size: 40),
            ],
          ),
          const SizedBox(height: 24),
          const SkeletonLine(width: 220, height: 24),
          const SizedBox(height: 8),
          const SkeletonLine(width: 180, height: 14),
          const SizedBox(height: 24),
          Skeleton(height: 140, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 24),
          const SkeletonLine(width: 120, height: 20),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Skeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Skeleton(
                  height: 100,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
