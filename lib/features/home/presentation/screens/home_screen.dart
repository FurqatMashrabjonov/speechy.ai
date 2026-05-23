import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/skeleton.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';
import 'package:speech_coach/features/assessment/domain/learning_plan_entity.dart';
import 'package:speech_coach/features/scenarios/data/scenario_repository.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/shared/widgets/user_avatar.dart';
import 'package:speech_coach/features/paywall/presentation/providers/subscription_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final firstName = ref.watch(authStateProvider.select((s) {
      final name = s.whenData((u) => u?.displayName).value;
      if (name == null || name.isEmpty) return 'Speaker';
      return name.split(' ').first;
    }));
    final plan = ref.watch(learningPlanProvider);

    // Today's session count vs daily target
    final todaySessions = ref.watch(progressProvider.select((p) {
      final today = DateTime.now();
      return p.sessionHistory
          .where((s) =>
              s.date.year == today.year &&
              s.date.month == today.month &&
              s.date.day == today.day)
          .length;
    }));
    final dailyTarget = plan?.sessionsPerDayTarget ?? 1;
    final dailyGoalDone = todaySessions >= dailyTarget;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              _Header(firstName: firstName).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),

              // Daily goal complete banner — shows when target reached
              if (dailyGoalDone && plan != null)
                _DailyGoalBanner(
                  sessionsToday: todaySessions,
                  target: dailyTarget,
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 350.ms)
                    .slideY(begin: -0.05),
              if (dailyGoalDone && plan != null) const SizedBox(height: 10),

              // Quick-start CTA — most important action, always visible
              if (plan != null && plan.nextStep != null && !dailyGoalDone)
                _QuickStartButton(plan: plan)
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 400.ms)
                    .slideY(begin: 0.04),
              if (plan != null && plan.nextStep != null && !dailyGoalDone)
                const SizedBox(height: 14),

              // Roadmap — fills all remaining vertical space
              Expanded(
                child: _RoadmapHero()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.04),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final String firstName;

  const _Header({required this.firstName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(progressProvider.select((p) => p.streak));
    final photoUrl = ref.watch(authStateProvider.select((s) => s.value?.photoURL));
    final tier = ref.watch(subscriptionProvider.select((s) => s.highestTier));

    return Row(
      children: [
        UserAvatar(photoUrl: photoUrl, name: firstName, radius: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(firstName, style: AppTypography.headlineSmall()),
        ),
        if (streak > 0) _StreakPill(streak: streak, isPremium: tier != null),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int streak;
  final bool isPremium;
  const _StreakPill({required this.streak, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    final colors = isPremium
        ? const [Color(0xFFB45309), Color(0xFFD97706)]
        : const [Color(0xFFFF6B35), Color(0xFFFF9500)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 16),
          const SizedBox(width: 3),
          Text(
            '$streak',
            style: AppTypography.titleMedium(color: Colors.white)
                .copyWith(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Daily Goal Banner ─────────────────────────────────────────────────────────

class _DailyGoalBanner extends StatelessWidget {
  final int sessionsToday;
  final int target;

  const _DailyGoalBanner({
    required this.sessionsToday,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final isIntensive = target >= 3;
    final List<Color> gradientColors = isIntensive
        ? [const Color(0xFFFF6B35), const Color(0xFFFF9500)]
        : [const Color(0xFF22C55E), const Color(0xFF16A34A)];
    final shadowColor = isIntensive
        ? const Color(0xFFFF6B35)
        : const Color(0xFF22C55E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isIntensive ? Icons.local_fire_department_rounded : Icons.check_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's goal complete!",
                  style: AppTypography.titleMedium(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  isIntensive
                      ? 'Great push — rest and come back tomorrow.'
                      : 'Come back tomorrow — spaced practice sticks.',
                  style: AppTypography.bodySmall(
                      color: Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$sessionsToday/$target',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                'today',
                style: AppTypography.labelSmall(
                    color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick-start CTA ──────────────────────────────────────────────────────────

class _QuickStartButton extends StatelessWidget {
  final LearningPlan plan;
  const _QuickStartButton({required this.plan});

  @override
  Widget build(BuildContext context) {
    final nextStep = plan.nextStep!;
    final scenario = ScenarioRepository().getById(nextStep.scenarioId);
    final title = scenario?.title ?? nextStep.scenarioId;

    return Tappable(
      onTap: () => context.push(
        '/scenario/${Uri.encodeComponent(nextStep.scenarioId)}',
        extra: {'trackId': plan.templateId, 'stepOrder': nextStep.order},
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6B5AED)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${plan.completedCount + 1} of ${plan.totalSteps}',
                    style: AppTypography.labelSmall(
                      color: Colors.white.withValues(alpha: 0.8),
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    title,
                    style: AppTypography.titleMedium(color: Colors.white)
                        .copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Roadmap Hero ──────────────────────────────────────────────────────────────

class _RoadmapHero extends ConsumerStatefulWidget {
  const _RoadmapHero();

  @override
  ConsumerState<_RoadmapHero> createState() => _RoadmapHeroState();
}

class _RoadmapHeroState extends ConsumerState<_RoadmapHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);

    if (plan == null) {
      return _NoRoadmapCard();
    }

    final currentIdx = plan.steps.indexWhere((s) => !s.isCompleted);
    final allComplete = currentIdx == -1;
    final effectiveIdx = allComplete ? plan.steps.length : currentIdx;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.divider, width: 2),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(plan.title,
                                style: AppTypography.titleMedium(),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (plan.chainLevel > 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Lvl ${plan.chainLevel}',
                                style: AppTypography.labelSmall(
                                        color: AppColors.primary)
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plan.completedCount} of ${plan.totalSteps} steps done',
                        style: AppTypography.labelSmall(
                            color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: plan.progressPercent,
                minHeight: 6,
                backgroundColor: context.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
          ),

          // ── Intensive mode banner ─────────────────────────────────────────
          if (plan.isIntensiveMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(
                      '${plan.daysUntilEvent} days to event — intensive mode',
                      style:
                          AppTypography.labelSmall(color: AppColors.error)
                              .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

          // ── Vertical Duolingo path ────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  itemCount: plan.steps.length,
                  separatorBuilder: (_, i) =>
                      _VerticalConnector(filled: i < effectiveIdx),
                  itemBuilder: (_, i) => _VerticalStepRow(
                    step: plan.steps[i],
                    globalIndex: i,
                    isCurrent: i == effectiveIdx,
                    isLocked: i > effectiveIdx,
                    pulseController: _pulse,
                    onTap: i <= effectiveIdx
                        ? () => context.push(
                              '/scenario/${Uri.encodeComponent(plan.steps[i].scenarioId)}',
                            )
                        : null,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.card.withValues(alpha: 0),
                            context.card,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Track complete banner ──────────────────────────────────────────
          if (allComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Tappable(
                onTap: () => ref.read(learningPlanProvider.notifier).unlockNextLevel(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
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
                            Text('Track Complete!',
                                style: AppTypography.titleMedium(
                                    color: AppColors.success)),
                            Text('Tap to start Level ${plan.chainLevel + 1} →',
                                style: AppTypography.bodySmall(
                                    color: context.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Level ${plan.chainLevel + 1}',
                          style: AppTypography.labelSmall(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Vertical step row ─────────────────────────────────────────────────────────

class _VerticalStepRow extends StatelessWidget {
  final PlanStep step;
  final int globalIndex;
  final bool isCurrent;
  final bool isLocked;
  final AnimationController pulseController;
  final VoidCallback? onTap;

  const _VerticalStepRow({
    required this.step,
    required this.globalIndex,
    required this.isCurrent,
    required this.isLocked,
    required this.pulseController,
    this.onTap,
  });

  Color get _difficultyColor {
    switch (step.difficulty.toLowerCase()) {
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
    final repo = ScenarioRepository();
    final scenario = repo.getById(step.scenarioId);
    final title = scenario?.title ?? step.scenarioId;

    final circleSize = isCurrent ? 56.0 : 44.0;
    final imagePath = AppImages.scenarioImageMap[step.scenarioId];
    final badgeSize = circleSize * 0.36;

    Widget circle = Stack(
      clipBehavior: Clip.none,
      children: [
        // Pulse ring for current
        if (isCurrent)
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, _) {
              final scale = 1.0 + pulseController.value * 0.12;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary
                        .withValues(alpha: 0.08 + pulseController.value * 0.08),
                  ),
                ),
              );
            },
          ),
        // Main circle
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: step.isCompleted
                  ? AppColors.success
                  : isCurrent
                      ? AppColors.primary
                      : const Color(0xFFD1D5DB),
              width: isCurrent ? 2.5 : 1.5,
            ),
          ),
          child: ClipOval(
            child: SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imagePath != null
                      ? ColorFiltered(
                          colorFilter: isLocked
                              ? const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      1, 0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent, BlendMode.dst),
                          child: Image.asset(imagePath,
                              width: circleSize,
                              height: circleSize,
                              fit: BoxFit.cover),
                        )
                      : Container(
                          color: AppColors.primary.withValues(alpha: isLocked ? 0.07 : 0.12),
                          child: Center(
                            child: Icon(
                              scenario?.icon ?? Icons.mic_rounded,
                              size: circleSize * 0.42,
                              color: AppColors.primary.withValues(alpha: isLocked ? 0.35 : 0.75),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
        // Lock corner badge
        if (isLocked)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xFF9E9E9E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(Icons.lock_rounded,
                  size: badgeSize * 0.55, color: Colors.white),
            ),
          ),
        // Completed badge
        if (step.isCompleted)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(Icons.check_rounded,
                  size: badgeSize * 0.6, color: Colors.white),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // Fixed-width column for circle (centered)
          SizedBox(
            width: 64,
            child: Center(child: circle),
          ),
          const SizedBox(width: 12),
          // Step info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium().copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isLocked
                        ? context.textTertiary
                        : isCurrent
                            ? AppColors.primary
                            : context.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? context.textTertiary
                            : _difficultyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      step.difficulty.toUpperCase(),
                      style: AppTypography.labelSmall(
                        color: isLocked
                            ? context.textTertiary
                            : _difficultyColor,
                      ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (step.isCompleted && step.score != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${step.score!.round()}% score',
                      style: AppTypography.labelSmall(
                              color: AppColors.success)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vertical connector ────────────────────────────────────────────────────────

class _VerticalConnector extends StatelessWidget {
  final bool filled;

  const _VerticalConnector({required this.filled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Center(
              child: Container(
                width: 2,
                height: 24,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.success
                      : context.divider,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No roadmap card ───────────────────────────────────────────────────────────

class _NoRoadmapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.divider, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('No track yet', style: AppTypography.titleMedium()),
          const SizedBox(height: 6),
          Text(
            'Take the quick assessment to get your personalized track.',
            style: AppTypography.bodySmall(color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          DuoButton.primary(
            text: 'Start Assessment',
            icon: Icons.assessment_rounded,
            width: double.infinity,
            onTap: () => context.push('/assessment'),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

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
              const SkeletonCircle(size: 42),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 80, height: 10),
                  SizedBox(height: 6),
                  SkeletonLine(width: 100, height: 20),
                ],
              ),
              const Spacer(),
              const SkeletonLine(width: 60, height: 28),
              const SizedBox(width: 8),
              const SkeletonLine(width: 60, height: 28),
            ],
          ),
          const SizedBox(height: 16),
          Skeleton(height: 44, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 14),
          Skeleton(height: 420, borderRadius: BorderRadius.circular(20)),
        ],
      ),
    );
  }
}
