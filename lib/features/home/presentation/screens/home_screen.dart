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
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/features/progress/domain/progress_entity.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/assessment/domain/learning_plan_entity.dart';
import 'package:speech_coach/features/scenarios/data/scenario_repository.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/features/paywall/data/usage_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = ref.watch(progressProvider.select((p) {
      final today = DateTime.now();
      final d = DateTime(today.year, today.month, today.day);
      return p.sessionHistory.where((s) {
        final sd = DateTime(s.date.year, s.date.month, s.date.day);
        return sd == d;
      }).length;
    }));
    final progress = ref.watch(progressProvider);
    final firstName = ref.watch(authStateProvider.select((s) {
      final name = s.whenData((u) => u?.displayName).value;
      if (name == null || name.isEmpty) return 'Speaker';
      return name.split(' ').first;
    }));
    final usage = ref.watch(usageServiceProvider);
    final plan = ref.watch(learningPlanProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              _Header(
                greeting: _greeting,
                firstName: firstName,
                progress: progress,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),

              // Daily goal strip — only when plan exists
              if (plan != null)
                _DailyGoalStrip(
                  target: plan.sessionsPerDayTarget,
                  done: todayCount,
                ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
              if (plan != null) const SizedBox(height: 14),

              // Free sessions banner
              if (!usage.isPro &&
                  usage.totalFreeSessionsUsed < UsageService.freeTotalSessions)
                _FreeSessionsBanner(remaining: usage.remainingSessions)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),
              if (!usage.isPro &&
                  usage.totalFreeSessionsUsed < UsageService.freeTotalSessions)
                const SizedBox(height: 14),

              // Quick-start CTA — most important action, always visible
              if (plan != null && plan.nextStep != null)
                _QuickStartButton(plan: plan)
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 400.ms)
                    .slideY(begin: 0.04),
              if (plan != null && plan.nextStep != null)
                const SizedBox(height: 14),

              // Roadmap — vertical Duolingo path
              _RoadmapHero()
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(begin: 0.04),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting;
  final String firstName;
  final UserProgress progress;

  const _Header({
    required this.greeting,
    required this.firstName,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting.toUpperCase(),
                style: AppTypography.labelSmall(color: context.textTertiary)
                    .copyWith(letterSpacing: 1.0, fontSize: 10),
              ),
              Text(firstName, style: AppTypography.headlineSmall()),
            ],
          ),
        ),
        _HeaderPill(
          icon: Icons.local_fire_department_rounded,
          value: '${progress.streak}',
          color: AppColors.error,
        ),
        const SizedBox(width: 8),
        _HeaderPill(
          icon: Icons.bar_chart_rounded,
          value: progress.avgScore > 0 ? '${progress.avgScore}' : '--',
          label: 'avg',
          color: AppColors.accent,
        ),
        const SizedBox(width: 8),
        Builder(builder: (ctx) {
          return Tappable(
            onTap: () => ctx.push('/settings'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.settings_outlined,
                  color: context.textSecondary, size: 18),
            ),
          );
        }),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final String? label;

  const _HeaderPill(
      {required this.icon, required this.value, required this.color, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.labelSmall(color: color)
                .copyWith(fontWeight: FontWeight.w800),
          ),
          if (label != null) ...[
            const SizedBox(width: 2),
            Text(
              label!,
              style: AppTypography.labelSmall(color: color.withValues(alpha: 0.7))
                  .copyWith(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Daily goal strip ─────────────────────────────────────────────────────────

class _DailyGoalStrip extends StatelessWidget {
  final int target;
  final int done;

  const _DailyGoalStrip({required this.target, required this.done});

  @override
  Widget build(BuildContext context) {
    final isComplete = done >= target;
    final color = isComplete ? AppColors.success : AppColors.primary;
    final dots = target.clamp(1, 5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isComplete
                ? Icons.check_circle_rounded
                : Icons.flag_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isComplete
                  ? 'Daily goal complete!'
                  : "Today's goal: $target session${target > 1 ? 's' : ''}",
              style: AppTypography.labelSmall(color: color)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(dots, (i) {
              final filled = i < done;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? color : color.withValues(alpha: 0.2),
                    border: Border.all(
                        color: color.withValues(alpha: 0.4), width: 1),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Free sessions banner ──────────────────────────────────────────────────────

class _FreeSessionsBanner extends StatelessWidget {
  final int remaining;

  const _FreeSessionsBanner({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final color = remaining == 1 ? AppColors.error : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              remaining == 1
                  ? 'Last free session! Unlock to keep going.'
                  : '$remaining free sessions remaining.',
              style: AppTypography.labelSmall(color: color)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Tappable(
            onTap: () => context.push('/paywall'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Unlock',
                  style: AppTypography.labelSmall(color: AppColors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
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

    // Show window: 2 completed before current + current + 4 upcoming = 7 max
    final startIdx = (effectiveIdx - 2).clamp(0, plan.steps.length);
    final endIdx = (startIdx + 7).clamp(0, plan.steps.length);
    final visibleSteps = plan.steps.sublist(startIdx, endIdx);

    final nextStep = plan.nextStep;
    final repo = ScenarioRepository();
    final nextScenario =
        nextStep != null ? repo.getById(nextStep.scenarioId) : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                backgroundColor: const Color(0xFFF0F0F0),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
            child: Column(
              children: [
                for (int i = 0; i < visibleSteps.length; i++) ...[
                  _VerticalStepRow(
                    step: visibleSteps[i],
                    globalIndex: startIdx + i,
                    isCurrent: (startIdx + i) == effectiveIdx,
                    isLocked: (startIdx + i) > effectiveIdx,
                    pulseController: _pulse,
                    onTap: (startIdx + i) == effectiveIdx
                        ? () => context.push(
                              '/scenario/${Uri.encodeComponent(visibleSteps[i].scenarioId)}',
                            )
                        : null,
                  ),
                  if (i < visibleSteps.length - 1)
                    _VerticalConnector(
                      filled: (startIdx + i) < effectiveIdx,
                    ),
                ],
                // "See all X steps" link if plan has more
                if (plan.totalSteps > 7)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Tappable(
                      onTap: () => context.push('/tracks/${plan.templateId}'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'See all ${plan.totalSteps} steps',
                            style: AppTypography.labelSmall(
                                    color: AppColors.primary)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── CTA ───────────────────────────────────────────────────────────
          if (allComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
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
                          Text('Track Complete!',
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
            )
          else if (nextScenario != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: DuoButton.primary(
                text: 'Start Step ${plan.completedCount + 1}: ${nextScenario.title}',
                icon: Icons.play_arrow_rounded,
                width: double.infinity,
                onTap: () => context.push(
                  '/scenario/${Uri.encodeComponent(nextStep!.scenarioId)}',
                ),
              ),
            )
          else
            const SizedBox(height: 16),
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
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? const Color(0xFFD1D5DB)
                            : _difficultyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      step.difficulty.toUpperCase(),
                      style: AppTypography.labelSmall(
                        color: isLocked
                            ? const Color(0xFFBBBBBB)
                            : _difficultyColor,
                      ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.bodyMedium().copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isLocked
                        ? const Color(0xFFBBBBBB)
                        : isCurrent
                            ? AppColors.primary
                            : context.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                      : const Color(0xFFE5E7EB),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: Column(
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
