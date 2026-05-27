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
import 'package:speech_coach/features/assessment/data/assessment_data.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final firstName = ref.watch(authStateProvider.select((s) {
      final u = s.whenData((u) => u).value;
      final name = u?.displayName;
      if (name != null && name.isNotEmpty) return name.split(' ').first;
      final email = u?.email ?? '';
      return email.isNotEmpty ? email.split('@').first : 'there';
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
                  plan: plan,
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
    final photoUrl = ref.watch(authStateProvider.select((s) => s.value?.photoURL));

    return Row(
      children: [
        UserAvatar(photoUrl: photoUrl, name: firstName, radius: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(firstName, style: AppTypography.headlineSmall()),
        ),
      ],
    );
  }
}

// ── Daily Goal Banner ─────────────────────────────────────────────────────────

class _DailyGoalBanner extends StatelessWidget {
  final int sessionsToday;
  final int target;
  final LearningPlan plan;

  const _DailyGoalBanner({
    required this.sessionsToday,
    required this.target,
    required this.plan,
  });

  String _subtitle() {
    final days = plan.daysUntilEvent;
    final title = plan.title;

    if (plan.eventDate == null) {
      return 'Great session! Keep building your skills.';
    }
    if (days < 0) {
      return 'Keep practicing — every session makes you sharper.';
    }
    if (days == 0) {
      return "Today's the day — you've prepared well!";
    }
    if (days == 1) {
      return 'Tomorrow is the day — you\'re ready for $title.';
    }
    if (days <= 7) {
      return '$days days until $title — you\'re on track.';
    }
    return '$days days left to nail $title. Great pace!';
  }

  @override
  Widget build(BuildContext context) {
    final days = plan.daysUntilEvent;
    final isUrgent = plan.eventDate != null && days >= 0 && days <= 3;
    final List<Color> gradientColors = isUrgent
        ? [const Color(0xFFFF6B35), const Color(0xFFFF9500)]
        : [const Color(0xFF22C55E), const Color(0xFF16A34A)];
    final shadowColor = isUrgent
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
                isUrgent ? Icons.local_fire_department_rounded : Icons.check_rounded,
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
                  _subtitle(),
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
          color: AppColors.primary,
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

  void _showTrackSwitcher(BuildContext context, LearningPlan activePlan,
      Map<String, dynamic> purchasedTiers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TrackSwitcherSheet(
        activePlan: activePlan,
        purchasedTrackIds: purchasedTiers.keys.toList(),
        onSwitch: (templateId) {
          Navigator.pop(context);
          ref.read(learningPlanProvider.notifier).switchRoadmap(templateId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);
    final purchasedTiers =
        ref.watch(subscriptionProvider.select((s) => s.purchasedTiers));

    if (plan == null) {
      return _NoRoadmapCard();
    }

    final currentIdx = plan.steps.indexWhere((s) => !s.isCompleted);
    final allComplete = currentIdx == -1;
    final effectiveIdx = allComplete ? plan.steps.length : currentIdx;
    final hasMultipleTracks = purchasedTiers.length > 1;

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
                if (hasMultipleTracks) ...[
                  const SizedBox(width: 8),
                  _TrackSwitcherChip(
                    count: purchasedTiers.length,
                    onTap: () =>
                        _showTrackSwitcher(context, plan, purchasedTiers),
                  ),
                ],
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

// ── Track Switcher Chip ───────────────────────────────────────────────────────

class _TrackSwitcherChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _TrackSwitcherChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.38),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz_rounded,
                size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Switch',
              style: AppTypography.labelSmall(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Track Switcher Bottom Sheet ───────────────────────────────────────────────

class _TrackSwitcherSheet extends StatelessWidget {
  final LearningPlan activePlan;
  final List<String> purchasedTrackIds;
  final void Function(String templateId) onSwitch;

  const _TrackSwitcherSheet({
    required this.activePlan,
    required this.purchasedTrackIds,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final metas = allRoadmapMetas
        .where((m) => purchasedTrackIds.contains(m.id))
        .toList();

    // Sort: active first
    metas.sort((a, b) =>
        a.id == activePlan.templateId ? -1 : b.id == activePlan.templateId ? 1 : 0);

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.35),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: context.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Switch Track',
                          style: AppTypography.titleMedium()),
                      Text(
                        '${metas.length} tracks unlocked',
                        style: AppTypography.labelSmall(
                            color: context.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Track list
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: metas.map((meta) {
                  final isActive = meta.id == activePlan.templateId;

                  if (isActive) {
                    // Active track — gradient card
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(meta.emoji,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  meta.title,
                                  style: AppTypography.titleMedium(
                                          color: Colors.white)
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Active',
                                  style: AppTypography.labelSmall(
                                          color: Colors.white)
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: activePlan.progressPercent,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${activePlan.completedCount} of ${activePlan.totalSteps} steps complete',
                            style: AppTypography.labelSmall(
                                    color:
                                        Colors.white.withValues(alpha: 0.85))
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }

                  // Inactive track — tappable card
                  return Tappable(
                    onTap: () => onSwitch(meta.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.divider, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: meta.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(meta.emoji,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meta.title,
                                  style: AppTypography.bodyMedium()
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meta.difficultyLabel,
                                  style: AppTypography.labelSmall(
                                      color: context.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Switch →',
                              style: AppTypography.labelSmall(
                                      color: AppColors.primary)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
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
