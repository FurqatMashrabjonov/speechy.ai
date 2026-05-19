import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/progress/domain/progress_entity.dart';
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';
import 'package:speech_coach/features/progress/presentation/widgets/score_trend_chart.dart';
import 'package:speech_coach/shared/widgets/skeleton.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realProgress = ref.watch(progressProvider);

    final progress = realProgress.sessionHistory.isNotEmpty
        ? realProgress
        : _demoProgress;
    final isDemo = realProgress.sessionHistory.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: _buildContent(context, progress, isDemo: isDemo),
      ),
    );
  }

  static final _demoProgress = UserProgress(
    totalXp: 2450,
    level: 5,
    levelTitle: 'Skilled',
    streak: 12,
    longestStreak: 18,
    totalSessions: 47,
    totalMinutes: 186,
    lastSessionDate: DateTime.now().subtract(const Duration(hours: 3)),
    badges: [
      'first_conversation',
      '5_day_streak',
      '10_day_streak',
      'dedicated_10',
      'interviews_5',
      'star_performer',
    ],
    sessionHistory: _generateDemoSessions(),
  );

  static List<SessionRecord> _generateDemoSessions() {
    final rng = Random(42);
    final now = DateTime.now();
    final categories = [
      'Interviews',
      'Presentations',
      'Public Speaking',
      'Conversations',
      'Debates',
      'Storytelling',
      'Phone Anxiety',
      'Dating & Social',
    ];

    final sessions = <SessionRecord>[];
    for (int i = 0; i < 47; i++) {
      final daysAgo = (i * 1.9).toInt() + rng.nextInt(2);
      final cat = categories[rng.nextInt(categories.length)];
      final base = 55 + rng.nextInt(35);
      sessions.add(SessionRecord(
        scenarioId: 'demo_$i',
        category: cat,
        overallScore: base,
        clarity: (base - 5 + rng.nextInt(15)).clamp(20, 100),
        confidence: (base - 8 + rng.nextInt(18)).clamp(20, 100),
        engagement: (base - 3 + rng.nextInt(12)).clamp(20, 100),
        relevance: (base + rng.nextInt(10)).clamp(20, 100),
        durationSeconds: 120 + rng.nextInt(300),
        xpEarned: 30 + rng.nextInt(70),
        date: now.subtract(Duration(days: daysAgo, hours: rng.nextInt(12))),
      ));
    }
    return sessions;
  }

  Widget _buildContent(BuildContext context, UserProgress progress,
      {bool isDemo = false}) {
    final sessions = progress.sessionHistory;
    final avgScore = sessions.isNotEmpty
        ? sessions.map((s) => s.overallScore).reduce((a, b) => a + b) /
            sessions.length
        : 0.0;
    final bestScore = sessions.isNotEmpty
        ? sessions.map((s) => s.overallScore).reduce(max)
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Expanded(
                child: Text('Results', style: AppTypography.headlineLarge()),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.streak}',
                      style:
                          AppTypography.titleMedium(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          // Demo banner
          if (isDemo) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sample data — complete sessions to see your real stats',
                      style: AppTypography.labelSmall(
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _BigStatCard(
                value: '${progress.totalSessions}',
                label: 'Sessions',
                icon: Icons.mic_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _BigStatCard(
                value: avgScore.toStringAsFixed(0),
                label: 'Avg Score',
                icon: Icons.speed_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _BigStatCard(
                value: '$bestScore',
                label: 'Best',
                icon: Icons.emoji_events_rounded,
                color: AppColors.gold,
              ),
              const SizedBox(width: 10),
              _BigStatCard(
                value: '${progress.totalMinutes}m',
                label: 'Practice',
                icon: Icons.timer_rounded,
                color: AppColors.skyBlue,
              ),
            ],
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
          const SizedBox(height: 20),

          // Score trend
          if (sessions.length >= 2) ...[
            _SectionCard(
              title: 'Score Trend',
              child: SizedBox(
                height: 200,
                child: ScoreTrendChart(sessions: sessions),
              ),
            ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
            const SizedBox(height: 16),
          ],

          // Badges
          if (progress.badges.isNotEmpty) ...[
            _SectionCard(
              title: 'Badges (${progress.badges.length})',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: progress.badges
                    .map((b) => _BadgeChip(badge: b))
                    .toList(),
              ),
            ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Overview Stat Card ─────────────────────────────────────────────────────

class _BigStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _BigStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleLarge(color: color)
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              label,
              style: AppTypography.labelSmall(color: context.textSecondary)
                  .copyWith(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium()),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Badge Chip ─────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final String badge;

  const _BadgeChip({required this.badge});

  static const _badgeInfo = {
    'first_conversation': ('First Chat', Icons.chat_bubble_rounded),
    '5_day_streak': ('5-Day Streak', Icons.local_fire_department_rounded),
    '10_day_streak': ('10-Day Streak', Icons.local_fire_department_rounded),
    'perfect_clarity': ('Perfect Clarity', Icons.visibility_rounded),
    'star_performer': ('Star Performer', Icons.star_rounded),
    'dedicated_10': ('10 Sessions', Icons.emoji_events_rounded),
    'dedicated_50': ('50 Sessions', Icons.workspace_premium_rounded),
    'interviews_5': ('Interview Pro', Icons.work_rounded),
    'presentations_5': ('Presenter', Icons.slideshow_rounded),
    'public_speaking_5': ('Public Speaker', Icons.campaign_rounded),
    'conversations_5': ('Conversationalist', Icons.chat_rounded),
    'debates_5': ('Debater', Icons.forum_rounded),
    'storytelling_5': ('Storyteller', Icons.auto_stories_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final info = _badgeInfo[badge];
    final label = info?.$1 ?? badge.replaceAll('_', ' ');
    final icon = info?.$2 ?? Icons.emoji_events_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall(color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ───────────────────────────────────────────────────────────────

class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const SkeletonLine(width: 180, height: 32),
          const SizedBox(height: 6),
          const SkeletonLine(width: 100, height: 14),
          const SizedBox(height: 24),
          Skeleton(height: 100, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 16),
          Skeleton(height: 80, borderRadius: BorderRadius.circular(16)),
          const SizedBox(height: 24),
          const SkeletonLine(width: 140, height: 20),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            Skeleton(height: 72, borderRadius: BorderRadius.circular(16)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
