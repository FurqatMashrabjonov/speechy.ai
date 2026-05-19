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
import 'package:speech_coach/features/paywall/data/usage_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final authState = ref.watch(authStateProvider);
    final usage = ref.watch(usageServiceProvider);
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

              // ── Header ────────────────────────────────────────────────────
              _Header(
                greeting: _greeting,
                firstName: firstName,
                progress: progress,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),

              // ── Free sessions remaining banner ────────────────────────────
              if (!usage.isPro && usage.totalFreeSessionsUsed < UsageService.freeTotalSessions)
                _FreeSessionsBanner(remaining: usage.remainingSessions)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),
              if (!usage.isPro && usage.totalFreeSessionsUsed < UsageService.freeTotalSessions)
                const SizedBox(height: 16),

              // ── HERO: Roadmap chain ───────────────────────────────────────
              _RoadmapHero()
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(begin: 0.04),
              const SizedBox(height: 20),

              // ── Stats row ─────────────────────────────────────────────────
              _StatsRow(progress: progress)
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 400.ms),
              const SizedBox(height: 20),

              // ── Quick Start ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Start', style: AppTypography.headlineSmall()),
                  Tappable(
                    onTap: () => context.go('/practice'),
                    child: Text('View All',
                        style: AppTypography.labelMedium(
                            color: AppColors.primary)),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
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
                      title: 'Browse',
                      subtitle: 'All scenarios',
                      icon: Icons.grid_view_rounded,
                      color: AppColors.cardBlue,
                      onTap: () => context.go('/practice'),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

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
        // Avatar
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

        // Name + greeting
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

        // Streak pill
        _HeaderPill(
          icon: Icons.local_fire_department_rounded,
          value: '${progress.streak}',
          color: AppColors.error,
        ),
        const SizedBox(width: 8),

        // XP pill
        _HeaderPill(
          icon: Icons.bolt_rounded,
          value: '${progress.totalXp}',
          color: AppColors.gold,
        ),
        const SizedBox(width: 8),

        // Settings
        Tappable(
          onTap: (context as Element).findAncestorStateOfType<_HomeScreenState>() != null
              ? () => Navigator.of(context).pushNamed('/settings')
              : null,
          child: Builder(builder: (ctx) {
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
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _HeaderPill(
      {required this.icon, required this.value, required this.color});

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
        ],
      ),
    );
  }
}

// ── Free sessions banner ──────────────────────────────────────────────────

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
                  ? 'Last free session! Unlock your roadmap to keep going.'
                  : '$remaining free sessions remaining. Unlock to continue after.',
              style: AppTypography.labelSmall(color: color)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Tappable(
            onTap: () => context.push('/paywall'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

// ── Roadmap Hero ─────────────────────────────────────────────────────────────

class _RoadmapHero extends ConsumerStatefulWidget {
  const _RoadmapHero();

  @override
  ConsumerState<_RoadmapHero> createState() => _RoadmapHeroState();
}

class _RoadmapHeroState extends ConsumerState<_RoadmapHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Auto-scroll to current step after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final plan = ref.read(learningPlanProvider);
    if (plan == null) return;
    final idx = plan.steps.indexWhere((s) => !s.isCompleted);
    if (idx > 0 && _scrollController.hasClients) {
      final nodeWidth = 56.0 + 8.0; // node + separator
      _scrollController.animateTo(
        (idx * nodeWidth).clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);
    final progress = ref.watch(progressProvider);

    if (plan == null) {
      return _NoRoadmapCard();
    }

    final nextStep = plan.nextStep;
    final repo = ScenarioRepository();
    final nextScenario =
        nextStep != null ? repo.getById(nextStep.scenarioId) : null;
    final completedIdx = plan.steps.indexWhere((s) => !s.isCompleted);
    final currentIdx = completedIdx == -1 ? plan.steps.length : completedIdx;

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
          // ── Top bar ──────────────────────────────────────────────────────
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
                                color: AppColors.primary.withValues(alpha: 0.1),
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
                        'Step ${plan.completedCount + 1} of ${plan.totalSteps}',
                        style: AppTypography.labelSmall(
                            color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Tappable(
                      onTap: () => context.push('/plan-summary'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('See Plan',
                            style: AppTypography.labelSmall(
                                    color: AppColors.primary)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tappable(
                      onTap: () => context.push('/roadmap-catalog'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.grid_view_rounded,
                                size: 13, color: Color(0xFF888888)),
                            const SizedBox(width: 4),
                            Text('All Roadmaps',
                                style: AppTypography.labelSmall(
                                    color: const Color(0xFF888888))),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      '${plan.daysUntilEvent} days to your event — intensive mode',
                      style: AppTypography.labelSmall(color: AppColors.error)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

          // ── Chain map ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: SizedBox(
              height: 90,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: plan.steps.length,
                separatorBuilder: (_, i) => _ChainConnector(
                  filled: i < currentIdx - 1,
                ),
                itemBuilder: (context, i) {
                  final step = plan.steps[i];
                  final isNext = i == currentIdx;
                  final isLocked = i > currentIdx;
                  return _ChainNode(
                    step: step,
                    index: i,
                    isNext: isNext,
                    isLocked: isLocked,
                    pulseController: _pulse,
                    onTap: isNext
                        ? () => context.push(
                              '/scenario/${Uri.encodeComponent(step.scenarioId)}',
                            )
                        : null,
                  );
                },
              ),
            ),
          ),

          // ── Week heatmap ───────────────────────────────────────────────────
          _WeekHeatmap(sessions: progress.sessionHistory),

          // ── Next step CTA ──────────────────────────────────────────────────
          if (plan.isComplete)
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
                          Text('Roadmap Complete! 🎉',
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
          Text('No roadmap yet', style: AppTypography.titleMedium()),
          const SizedBox(height: 6),
          Text(
            'Take the quick assessment to get your personalized learning plan.',
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

// ── Chain node ────────────────────────────────────────────────────────────────

class _ChainNode extends StatelessWidget {
  final PlanStep step;
  final int index;
  final bool isNext;
  final bool isLocked;
  final AnimationController pulseController;
  final VoidCallback? onTap;

  const _ChainNode({
    required this.step,
    required this.index,
    required this.isNext,
    required this.isLocked,
    required this.pulseController,
    this.onTap,
  });

  Color get _difficultyColor {
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing ring for current step
            if (isNext)
              AnimatedBuilder(
                animation: pulseController,
                builder: (_, child) {
                  final scale = 1.0 + pulseController.value * 0.12;
                  final opacity = 0.15 + pulseController.value * 0.1;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                AppColors.primary.withValues(alpha: opacity),
                          ),
                        ),
                      ),
                      child!,
                    ],
                  );
                },
                child: _NodeCircle(
                  step: step,
                  isNext: isNext,
                  isLocked: isLocked,
                ),
              )
            else
              _NodeCircle(
                step: step,
                isNext: isNext,
                isLocked: isLocked,
              ),

            const SizedBox(height: 5),

            // Difficulty dot or score
            if (step.isCompleted && step.score != null)
              Text(
                '${step.score!.round()}%',
                style: AppTypography.labelSmall(color: AppColors.success)
                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
              )
            else if (!isLocked)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _difficultyColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  final PlanStep step;
  final bool isNext;
  final bool isLocked;

  const _NodeCircle({
    required this.step,
    required this.isNext,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Widget icon;

    if (step.isCompleted) {
      bgColor = AppColors.success.withValues(alpha: 0.12);
      borderColor = AppColors.success;
      icon = const Icon(Icons.check_rounded, color: AppColors.success, size: 20);
    } else if (isNext) {
      bgColor = AppColors.primary.withValues(alpha: 0.12);
      borderColor = AppColors.primary;
      icon = const Icon(Icons.play_arrow_rounded,
          color: AppColors.primary, size: 22);
    } else if (isLocked) {
      bgColor = const Color(0xFFF3F4F6);
      borderColor = const Color(0xFFD1D5DB);
      icon = const Icon(Icons.lock_rounded,
          color: Color(0xFFBBBBBB), size: 16);
    } else {
      bgColor = const Color(0xFFF3F4F6);
      borderColor = const Color(0xFFD1D5DB);
      icon = const Icon(Icons.lock_rounded,
          color: Color(0xFFBBBBBB), size: 16);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isNext ? 2.5 : 1.5,
        ),
      ),
      child: Center(child: icon),
    );
  }
}

// ── Chain connector ───────────────────────────────────────────────────────────

class _ChainConnector extends StatelessWidget {
  final bool filled;

  const _ChainConnector({required this.filled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 22),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: filled ? AppColors.success : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserProgress progress;

  const _StatsRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final avgScore = progress.sessionHistory.isNotEmpty
        ? (progress.sessionHistory
                    .map((s) => s.overallScore)
                    .reduce((a, b) => a + b) /
                progress.sessionHistory.length)
            .round()
        : 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
              color: AppColors.error,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.bolt_rounded,
              value: '${progress.totalXp}',
              label: 'XP',
              color: AppColors.gold,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.chat_bubble_rounded,
              value: '${progress.totalSessions}',
              label: 'Sessions',
              color: AppColors.skyBlue,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.star_rounded,
              value: avgScore > 0 ? '$avgScore%' : '--',
              label: 'Avg Score',
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: context.divider);
  }
}

// ── Quick Start card ──────────────────────────────────────────────────────────

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
            Text(subtitle,
                style: AppTypography.labelSmall(color: context.textTertiary)),
          ],
        ),
      ),
    );
  }
}

// ── Stat item ─────────────────────────────────────────────────────────────────

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
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headlineMedium(color: color)
              .copyWith(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        Text(label,
            style:
                AppTypography.labelSmall(color: context.textSecondary)),
      ],
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
          const SizedBox(height: 20),
          Skeleton(height: 240, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 20),
          Skeleton(height: 72, borderRadius: BorderRadius.circular(16)),
          const SizedBox(height: 20),
          const SkeletonLine(width: 120, height: 20),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: Skeleton(
                      height: 100,
                      borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 12),
              Expanded(
                  child: Skeleton(
                      height: 100,
                      borderRadius: BorderRadius.circular(16))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Week Heatmap ──────────────────────────────────────────────────────────────

class _WeekHeatmap extends StatelessWidget {
  final List<SessionRecord> sessions;

  const _WeekHeatmap({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final today = now.weekday - 1; // 0 = Mon, 6 = Sun

    final practicedDays = <int>{};
    for (final s in sessions) {
      final diff = DateTime(s.date.year, s.date.month, s.date.day)
          .difference(DateTime(monday.year, monday.month, monday.day))
          .inDays;
      if (diff >= 0 && diff < 7) practicedDays.add(diff);
    }

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: AppTypography.labelSmall(color: context.textTertiary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final practiced = practicedDays.contains(i);
              final isFuture = i > today;
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: practiced
                          ? AppColors.primary
                          : isFuture
                              ? Colors.transparent
                              : AppColors.primary.withValues(alpha: 0.06),
                      border: Border.all(
                        color: practiced
                            ? AppColors.primary
                            : const Color(0xFFDDDDDD),
                        width: 1.5,
                      ),
                    ),
                    child: practiced
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: AppColors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabels[i],
                    style: AppTypography.labelSmall(
                      color: practiced
                          ? AppColors.primary
                          : context.textTertiary,
                    ).copyWith(fontSize: 11),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
