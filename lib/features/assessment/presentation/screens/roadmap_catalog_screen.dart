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
import 'package:speech_coach/core/analytics/analytics_service.dart';
import 'package:speech_coach/features/paywall/domain/track_tier.dart';
import 'package:speech_coach/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class RoadmapCatalogScreen extends ConsumerWidget {
  const RoadmapCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(learningPlanProvider);
    final sub = ref.watch(subscriptionProvider);
    final activeId = plan?.templateId;

    // Sort: active → purchased → locked
    final sorted = [
      ...allRoadmapMetas.where((m) => m.id == activeId),
      ...allRoadmapMetas.where((m) => m.id != activeId && sub.purchasedTiers.containsKey(m.id)),
      ...allRoadmapMetas.where((m) => m.id != activeId && !sub.purchasedTiers.containsKey(m.id)),
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
                  Text('Tracks', style: AppTypography.headlineLarge()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: sorted.length,
                separatorBuilder: (context, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final meta = sorted[index];
                  final isActive = meta.id == activeId;
                  final tier = sub.tierForTrack(meta.id);
                  final isUnlocked = tier != null || isActive;
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
                    tier: tier,
                    completedSteps: completedSteps,
                    totalSteps: totalSteps,
                    onTap: () {
                      AnalyticsService.instance.logTrackSelected(trackId: meta.id);
                      context.push('/tracks/${meta.id}');
                    },
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
  final TrackTier? tier;
  final int completedSteps;
  final int totalSteps;
  final VoidCallback onTap;

  const _TrackCard({
    required this.meta,
    required this.isActive,
    required this.isUnlocked,
    required this.tier,
    required this.completedSteps,
    required this.totalSteps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !isUnlocked;

    return Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.07)
              : isLocked
                  ? context.surface
                  : context.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : context.divider,
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
                Widget image = bannerPath != null
                    ? Image.asset(bannerPath,
                        width: 64, height: 64, fit: BoxFit.cover)
                    : Container(
                        width: 64,
                        height: 64,
                        color: meta.color.withValues(alpha: 0.15),
                      );
                return image;
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
                      else if (tier != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            tier!.displayName,
                            style: AppTypography.labelSmall(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        )
                      else
                        Icon(
                          isLocked
                              ? Icons.lock_rounded
                              : Icons.chevron_right_rounded,
                          size: isLocked ? 16 : 20,
                          color: context.textTertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta.description,
                    style: AppTypography.bodySmall(color: context.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (isActive) ...[
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
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$completedSteps/$totalSteps',
                          style: AppTypography.labelSmall(
                                  color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      '${meta.stepCount} steps',
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
