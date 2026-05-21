import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/assessment/data/assessment_data.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class RoadmapCatalogScreen extends ConsumerWidget {
  const RoadmapCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(learningPlanProvider);
    final sub = ref.watch(subscriptionProvider);
    final activeId = plan?.templateId;
    final isPro = sub.isPro;

    // Active track first, then rest
    final sorted = [
      ...allRoadmapMetas.where((m) => m.id == activeId),
      ...allRoadmapMetas.where((m) => m.id != activeId),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tracks', style: AppTypography.titleLarge()),
                        Text(
                          isPro
                              ? 'All tracks unlocked — switch any time'
                              : 'Your active track is free. Unlock all 5.',
                          style: AppTypography.bodySmall(
                              color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
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
                          Text('Pro',
                              style: AppTypography.labelSmall(
                                  color: AppColors.primary)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final meta = sorted[index];
                  final isActive = meta.id == activeId;
                  final isUnlocked = isPro || isActive;
                  final completedSteps = isActive
                      ? (plan?.steps.where((s) => s.isCompleted).length ?? 0)
                      : 0;
                  final totalSteps = isActive
                      ? (plan?.steps.length ?? meta.stepCount)
                      : meta.stepCount;

                  return _TrackCard(
                    meta: meta,
                    isActive: isActive,
                    isUnlocked: isUnlocked,
                    completedSteps: completedSteps,
                    totalSteps: totalSteps,
                    onTap: () => context.push('/tracks/${meta.id}'),
                  )
                      .animate(delay: (index * 60).ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final RoadmapMeta meta;
  final bool isActive;
  final bool isUnlocked;
  final int completedSteps;
  final int totalSteps;
  final VoidCallback onTap;

  const _TrackCard({
    required this.meta,
    required this.isActive,
    required this.isUnlocked,
    required this.completedSteps,
    required this.totalSteps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : const Color(0xFFE5E5E5),
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Banner thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: () {
                final bannerPath = AppImages.trackBannerMap[meta.id];
                if (bannerPath != null) {
                  return Image.asset(
                    bannerPath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  );
                }
                return Container(
                  width: 64,
                  height: 64,
                  color: meta.color.withValues(alpha: 0.15),
                );
              }(),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.title,
                          style: AppTypography.titleMedium().copyWith(
                            color: isActive ? AppColors.primary : null,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Active',
                              style: AppTypography.labelSmall(
                                      color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        )
                      else if (!isUnlocked)
                        const Icon(Icons.lock_rounded,
                            size: 16, color: Color(0xFFBBBBBB)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          size: 20,
                          color: isActive
                              ? AppColors.primary
                              : const Color(0xFFBBBBBB)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta.description,
                    style: AppTypography.bodySmall(
                        color: context.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalSteps > 0
                                  ? completedSteps / totalSteps
                                  : 0,
                              minHeight: 5,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$completedSteps/$totalSteps',
                          style: AppTypography.labelSmall(color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      '${meta.stepCount} steps · ${meta.difficultyLabel}',
                      style: AppTypography.labelSmall(
                              color: context.textTertiary)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
