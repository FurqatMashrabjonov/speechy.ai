import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/assessment/data/assessment_data.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:speech_coach/shared/widgets/duo_button.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class RoadmapCatalogScreen extends ConsumerWidget {
  const RoadmapCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(learningPlanProvider);
    final sub = ref.watch(subscriptionProvider);
    final activeId = plan?.templateId;
    final isPro = sub.isPro;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Tappable(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.close_rounded, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('All Roadmaps', style: AppTypography.titleLarge()),
                  const Spacer(),
                  if (isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('All Unlocked',
                              style: AppTypography.labelSmall(
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                isPro
                    ? 'Switch between any roadmap — your XP and streak carry over.'
                    : 'Your active roadmap is free. Unlock all 5 for one price.',
                style:
                    AppTypography.bodySmall(color: context.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: allRoadmapMetas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final meta = allRoadmapMetas[index];
                  final isActive = meta.id == activeId;
                  final isUnlocked = isPro || isActive;
                  final completedSteps = isActive
                      ? (plan?.steps
                              .where((s) => s.isCompleted)
                              .length ??
                          0)
                      : 0;
                  final totalSteps = isActive ? (plan?.steps.length ?? 15) : 15;

                  return _RoadmapCard(
                    meta: meta,
                    isActive: isActive,
                    isUnlocked: isUnlocked,
                    completedSteps: completedSteps,
                    totalSteps: totalSteps,
                    isPurchasing: sub.isPurchasing,
                    onContinue: () => context.pop(),
                    onSwitch: () async {
                      await ref
                          .read(learningPlanProvider.notifier)
                          .switchRoadmap(meta.id);
                      if (context.mounted) context.go('/home');
                    },
                    onUnlock: () => context.push('/paywall'),
                  ).animate(delay: (index * 80).ms).fadeIn(duration: 350.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
                      );
                },
              ),
            ),

            // Bundle CTA at bottom if not pro
            if (!isPro)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                child: DuoButton.primary(
                  text: 'Unlock All 5 Roadmaps — \$34.99',
                  icon: Icons.workspace_premium_rounded,
                  width: double.infinity,
                  onTap: () => context.push('/paywall'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  final RoadmapMeta meta;
  final bool isActive;
  final bool isUnlocked;
  final int completedSteps;
  final int totalSteps;
  final bool isPurchasing;
  final VoidCallback onContinue;
  final VoidCallback onSwitch;
  final VoidCallback onUnlock;

  const _RoadmapCard({
    required this.meta,
    required this.isActive,
    required this.isUnlocked,
    required this.completedSteps,
    required this.totalSteps,
    required this.isPurchasing,
    required this.onContinue,
    required this.onSwitch,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isActive
            ? meta.color.withValues(alpha: 0.07)
            : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? meta.color.withValues(alpha: 0.5)
              : const Color(0xFFE5E5E5),
          width: isActive ? 2 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: meta.color.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: emoji + title + badge
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(meta.title,
                              style: AppTypography.titleMedium()),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: meta.color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Active',
                              style:
                                  AppTypography.labelSmall(color: Colors.white)
                                      .copyWith(fontWeight: FontWeight.w700),
                            ),
                          )
                        else if (!isUnlocked)
                          const Icon(Icons.lock_rounded,
                              size: 18, color: Color(0xFFBBBBBB)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.description,
                      style: AppTypography.bodySmall(
                          color: context.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar (active roadmap only)
          if (isActive) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedSteps / $totalSteps steps',
                  style: AppTypography.labelSmall(color: context.textSecondary),
                ),
                Text(
                  '${((completedSteps / totalSteps) * 100).toInt()}%',
                  style: AppTypography.labelSmall(color: meta.color)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: completedSteps / totalSteps,
                minHeight: 7,
                backgroundColor: meta.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(meta.color),
              ),
            ),
          ],

          // Difficulty chips
          const SizedBox(height: 12),
          Row(
            children: [
              _DifficultyChip(
                  label: '15 steps', icon: Icons.route_rounded, color: meta.color),
              const SizedBox(width: 8),
              _DifficultyChip(
                  label: 'Easy → Hard',
                  icon: Icons.trending_up_rounded,
                  color: meta.color),
            ],
          ),

          const SizedBox(height: 14),

          // Action button
          if (isActive)
            SizedBox(
              width: double.infinity,
              child: DuoButton.primary(
                text: 'Continue',
                icon: Icons.play_arrow_rounded,
                onTap: onContinue,
              ),
            )
          else if (isUnlocked)
            SizedBox(
              width: double.infinity,
              child: DuoButton.secondary(
                text: 'Switch to This Roadmap',
                onTap: onSwitch,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: Tappable(
                onTap: onUnlock,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_open_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Unlock — \$9.99',
                        style: AppTypography.labelMedium(
                                color: AppColors.primary)
                            .copyWith(fontWeight: FontWeight.w700),
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

class _DifficultyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _DifficultyChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style:
                  AppTypography.labelSmall(color: color)),
        ],
      ),
    );
  }
}
