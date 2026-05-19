import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  static const _categories = [
    ('Presentations', Icons.slideshow_rounded, AppColors.cardPeach),
    ('Interviews', Icons.work_outline_rounded, AppColors.cardBlue),
    ('Public Speaking', Icons.campaign_rounded, AppColors.cardLavender),
    ('Conversations', Icons.chat_bubble_outline_rounded, AppColors.cardMint),
    ('Debates', Icons.forum_rounded, AppColors.cardYellow),
    ('Storytelling', Icons.auto_stories_rounded, AppColors.cardRose),
    ('Phone Anxiety', Icons.phone_in_talk_rounded, AppColors.cardPeach),
    ('Dating & Social', Icons.favorite_outline_rounded, AppColors.cardBlue),
    ('Conflict & Boundaries', Icons.shield_outlined, AppColors.cardLavender),
    ('Social Situations', Icons.groups_rounded, AppColors.cardMint),
  ];

  static const _categoryCounts = {
    'Presentations': 5,
    'Interviews': 5,
    'Public Speaking': 5,
    'Conversations': 5,
    'Debates': 5,
    'Storytelling': 5,
    'Phone Anxiety': 5,
    'Dating & Social': 5,
    'Conflict & Boundaries': 5,
    'Social Situations': 5,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practice',
                    style: AppTypography.displayMedium(),
                  ),
                  Text(
                    'Choose a category to start',
                    style: AppTypography.bodySmall(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),

              // Categories
              Text(
                'Categories',
                style: AppTypography.headlineSmall(),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final (name, icon, color) = _categories[index];
                  final count = _categoryCounts[name] ?? 5;
                  return _CategoryCard(
                    name: name,
                    icon: icon,
                    color: color,
                    count: count,
                    onTap: () => context.push(
                      '/scenarios/${Uri.encodeComponent(name)}',
                    ),
                  );
                },
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}


class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = AppImages.categoryImageMap[name];

    return Tappable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Big image area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildIconFallback(),
                        )
                      : _buildIconFallback(),
                ),
              ),
            ),
            // Text area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleMedium(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 14,
                          color: context.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count scenarios',
                          style: AppTypography.labelSmall(
                            color: context.textTertiary,
                          ),
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

  Widget _buildIconFallback() {
    return Container(
      color: AppColors.white.withValues(alpha: 0.6),
      child: Center(
        child: Icon(icon, color: AppColors.primary, size: 40),
      ),
    );
  }
}
