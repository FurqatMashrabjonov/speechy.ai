import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/scenarios/domain/scenario_entity.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:speech_coach/shared/widgets/skeleton.dart';

class ScenarioListScreen extends ConsumerWidget {
  final String category;

  const ScenarioListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(scenariosByCategoryProvider(category));
    final categoryImage = AppImages.categoryImageMap[category];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Tappable(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category, style: AppTypography.headlineSmall()),
                        Text(
                          '${scenarios.length} scenarios',
                          style: AppTypography.bodySmall(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Category image in header
                  if (categoryImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        categoryImage,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scenario grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: scenarios.length,
                itemBuilder: (context, index) {
                  final scenario = scenarios[index];
                  return _ScenarioCard(scenario: scenario)
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 60 * index),
                        duration: 400.ms,
                      )
                      .slideY(begin: 0.06);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScenarioListSkeleton extends StatelessWidget {
  const ScenarioListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const SkeletonLine(width: 160, height: 24),
          const SizedBox(height: 6),
          const SkeletonLine(width: 100, height: 14),
          const SizedBox(height: 20),
          for (int i = 0; i < 2; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Skeleton(
                    height: 200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Skeleton(
                    height: 200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;

  const _ScenarioCard({required this.scenario});

  static Color _difficultyColor(String difficulty) {
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

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(scenario.difficulty);

    return Tappable(
      onTap: () {
        context.push(
          '/scenario/${Uri.encodeComponent(scenario.id)}',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: scenario.categoryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scenario.categoryColor.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: scenario.imagePath != null
                        ? Image.asset(
                            scenario.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildImageFallback(),
                          )
                        : _buildImageFallback(),
                  ),
                ),
              ),
            ),
            // Text + tag
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      scenario.title,
                      style: AppTypography.titleMedium(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${scenario.durationMinutes}m',
                          style: AppTypography.labelSmall(
                            color: context.textTertiary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: AppTypography.labelSmall(
                              color: context.textTertiary,
                            ),
                          ),
                        ),
                        Text(
                          scenario.difficulty,
                          style: AppTypography.labelSmall(
                            color: diffColor,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: scenario.categoryColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          scenario.icon,
          color: scenario.categoryColor,
          size: 36,
        ),
      ),
    );
  }
}

