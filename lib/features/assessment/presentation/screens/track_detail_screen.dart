import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/assessment/data/assessment_data.dart';
import 'package:speech_coach/features/assessment/domain/learning_plan_entity.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:speech_coach/features/scenarios/domain/scenario_entity.dart';
import 'package:speech_coach/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class TrackDetailScreen extends ConsumerWidget {
  final String trackId;

  const TrackDetailScreen({super.key, required this.trackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = allRoadmapMetas.firstWhere(
      (m) => m.id == trackId,
      orElse: () => allRoadmapMetas.first,
    );
    final plan = ref.watch(learningPlanProvider);
    final sub = ref.watch(subscriptionProvider);
    final isActive = plan?.templateId == trackId;
    final isPro = sub.isPro;
    final isUnlocked = isPro || isActive;

    final displayPlan =
        isActive ? plan! : generatePlanFromTemplateId(trackId);
    final steps = displayPlan.steps;
    final currentOrder = isActive ? (plan!.nextStep?.order ?? -1) : -1;

    final nextStep = isActive ? plan!.nextStep : null;
    final nextScenario = nextStep != null
        ? ref.watch(scenarioByIdProvider(nextStep.scenarioId))
        : null;

    return Scaffold(
      backgroundColor: context.isDark ? AppColors.backgroundDark : const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(meta: meta, isActive: isActive, isPro: isPro),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final step = steps[i];
                      final scenario =
                          ref.watch(scenarioByIdProvider(step.scenarioId));
                      return _StepTile(
                        step: step,
                        scenario: scenario,
                        isCurrent: isActive && step.order == currentOrder,
                        isTrackUnlocked: isUnlocked,
                        isLast: i == steps.length - 1,
                        trackColor: meta.color,
                      )
                          .animate(delay: (i * 25).ms)
                          .fadeIn(duration: 220.ms)
                          .slideY(begin: 0.05, end: 0, duration: 220.ms, curve: Curves.easeOut);
                    },
                    childCount: steps.length,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomCta(
              meta: meta,
              isActive: isActive,
              isUnlocked: isUnlocked,
              nextStep: nextStep,
              nextScenario: nextScenario,
              planComplete: isActive && (plan?.isComplete ?? false),
              onContinue: () {
                final s = nextScenario;
                if (s == null) return;
                context.push(
                  '/conversation/${Uri.encodeComponent(s.category)}',
                  extra: {
                    'scenarioId': s.id,
                    'scenarioTitle': s.title,
                    'scenarioPrompt': s.systemPrompt,
                    'durationMinutes': s.durationMinutes,
                    'userRole': s.userRole,
                  },
                );
              },
              onSwitch: () async {
                await ref
                    .read(learningPlanProvider.notifier)
                    .switchRoadmap(trackId);
                if (context.mounted) context.pop();
              },
              onUnlock: () => context.push('/paywall'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header
// ---------------------------------------------------------------------------

class _HeroHeader extends StatelessWidget {
  final RoadmapMeta meta;
  final bool isActive;
  final bool isPro;

  const _HeroHeader({
    required this.meta,
    required this.isActive,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    final bannerPath = AppImages.trackBannerMap[meta.id];
    return Column(
      children: [
        // Banner image with gradient + nav overlay
        Stack(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: bannerPath != null
                  ? Image.asset(bannerPath, fit: BoxFit.cover)
                  : Container(color: meta.color.withValues(alpha: 0.2)),
            ),
            // Bottom gradient so content below blends
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            // Safe area + nav row
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    if (isPro)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Pro',
                                  style: AppTypography.labelSmall(
                                          color: Colors.white)
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Title + emoji over banner bottom
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: Text(
                meta.title,
                style: AppTypography.titleLarge()
                    .copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        // Description + chips below banner
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.isDark
                ? AppColors.backgroundDark
                : const Color(0xFFF7F7F7),
            border: Border(
              bottom: BorderSide(
                color: meta.color.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta.description,
                style: AppTypography.bodyMedium(color: context.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    label: '${meta.stepCount} steps',
                    icon: Icons.list_rounded,
                    color: meta.color,
                  ),
                  _InfoChip(
                    label: meta.difficultyLabel,
                    icon: Icons.trending_up_rounded,
                    color: meta.color,
                  ),
                  if (isActive)
                    _InfoChip(
                      label: 'Active',
                      icon: Icons.play_circle_filled_rounded,
                      color: AppColors.success,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: AppTypography.labelSmall(color: color)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step tile
// ---------------------------------------------------------------------------

class _StepTile extends StatelessWidget {
  final PlanStep step;
  final Scenario? scenario;
  final bool isCurrent;
  final bool isTrackUnlocked;
  final bool isLast;
  final Color trackColor;

  const _StepTile({
    required this.step,
    required this.scenario,
    required this.isCurrent,
    required this.isTrackUnlocked,
    required this.isLast,
    required this.trackColor,
  });

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
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
    final isCompleted = isTrackUnlocked && step.isCompleted;
    final passed = isCompleted && step.isPassed;
    final locked = !isTrackUnlocked;

    final textColor = locked
        ? context.textTertiary
        : isCompleted || isCurrent
            ? null
            : context.textSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: circle + line
          SizedBox(
            width: 48,
            child: Column(
              children: [
                _ScenarioAvatar(
                  imagePath: scenario?.imagePath,
                  fallbackIcon: scenario?.icon,
                  stepNumber: step.order + 1,
                  size: 56,
                  isCompleted: isCompleted,
                  isPassed: passed,
                  isCurrent: isCurrent,
                  isLocked: locked,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.4)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right: content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 4),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.07)
                      : context.isDark
                          ? AppColors.surfaceDark
                          : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : const Color(0xFFEEEEEE),
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${step.order + 1}',
                            style: AppTypography.labelSmall(color: AppColors.primary)
                                .copyWith(fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            scenario?.title ?? step.scenarioId,
                            style: AppTypography.bodyMedium()
                                .copyWith(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (isCompleted && step.score != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: (passed ? AppColors.success : AppColors.warning)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${step.score!.round()}',
                              style: AppTypography.labelSmall(
                                      color: passed
                                          ? AppColors.success
                                          : AppColors.warning)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (scenario?.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        scenario!.description,
                        style: AppTypography.bodySmall(color: context.textTertiary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _difficultyColor(step.difficulty)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _capitalize(step.difficulty),
                            style: AppTypography.labelSmall(
                                    color: _difficultyColor(step.difficulty))
                                .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pass: ${step.minPassScore}+',
                          style: AppTypography.labelSmall(
                                  color: context.textTertiary)
                              .copyWith(fontSize: 10),
                        ),
                        if (isCurrent) ...[
                          const Spacer(),
                          Text(
                            'Up next',
                            style: AppTypography.labelSmall(color: AppColors.primary)
                                .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                          ),
                        ],
                      ],
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// Scenario avatar (circular image with state overlays)
// ---------------------------------------------------------------------------

class _ScenarioAvatar extends StatelessWidget {
  final String? imagePath;
  final IconData? fallbackIcon;
  final int stepNumber;
  final double size;
  final bool isCompleted;
  final bool isPassed;
  final bool isCurrent;
  final bool isLocked;

  const _ScenarioAvatar({
    required this.imagePath,
    required this.fallbackIcon,
    required this.stepNumber,
    required this.size,
    required this.isCompleted,
    required this.isPassed,
    required this.isCurrent,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.38;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent
                  ? AppColors.primary
                  : isCompleted
                      ? (isPassed ? AppColors.success : AppColors.warning)
                      : const Color(0xFFE0E0E0),
              width: isCurrent ? 2.5 : 1.5,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
              fit: StackFit.expand,
              children: [
                // Image or colored fallback
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
                        child: Image.asset(
                          imagePath!,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        color: AppColors.primary.withValues(alpha: isLocked ? 0.07 : 0.12),
                        child: Center(
                          child: Icon(
                            fallbackIcon ?? Icons.mic_rounded,
                            size: size * 0.42,
                            color: AppColors.primary.withValues(alpha: isLocked ? 0.35 : 0.75),
                          ),
                        ),
                      ),
              ],
              ),
            ),
          ),
        ),
        // Lock badge (corner, not overlay)
        if (isLocked)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: const Color(0xFF9E9E9E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: size * 0.18,
                color: Colors.white,
              ),
            ),
          ),
        // Completed badge
        if (isCompleted)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: isPassed ? AppColors.success : AppColors.warning,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                isPassed ? Icons.check_rounded : Icons.replay_rounded,
                size: badgeSize * 0.6,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom CTA
// ---------------------------------------------------------------------------

class _BottomCta extends StatelessWidget {
  final RoadmapMeta meta;
  final bool isActive;
  final bool isUnlocked;
  final bool planComplete;
  final PlanStep? nextStep;
  final Scenario? nextScenario;
  final VoidCallback onContinue;
  final VoidCallback onSwitch;
  final VoidCallback onUnlock;

  const _BottomCta({
    required this.meta,
    required this.isActive,
    required this.isUnlocked,
    required this.planComplete,
    required this.nextStep,
    required this.nextScenario,
    required this.onContinue,
    required this.onSwitch,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          top: BorderSide(
            color: context.isDark
                ? AppColors.dividerDark
                : const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: _buildButton(context),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (isActive) {
      if (planComplete) {
        return _PrimaryButton(
          label: 'Track Complete — View Progress',
          icon: Icons.emoji_events_rounded,
          color: AppColors.success,
          onTap: () => context.push('/progress'),
        );
      }
      final stepNum = (nextStep?.order ?? 0) + 1;
      return _PrimaryButton(
        label: 'Continue  ·  Step $stepNum',
        icon: Icons.play_arrow_rounded,
        color: AppColors.primary,
        onTap: onContinue,
      );
    }

    if (isUnlocked) {
      return _PrimaryButton(
        label: 'Switch to This Track',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.primary,
        onTap: onSwitch,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(
          label: 'Unlock All Tracks',
          icon: Icons.lock_open_rounded,
          color: AppColors.primary,
          onTap: onUnlock,
        ),
        const SizedBox(height: 8),
        Text(
          'Current track always free',
          style: AppTypography.bodySmall(color: context.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.bodyMedium(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
