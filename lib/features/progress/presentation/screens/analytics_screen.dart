import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/progress/domain/progress_entity.dart';
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';
import 'package:speech_coach/shared/widgets/skeleton.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild when sessionHistory changes — not on every streak/xp tick.
    final hasRealSessions = ref.watch(
      progressProvider.select((p) => p.sessionHistory.isNotEmpty),
    );
    final realProgress = hasRealSessions ? ref.watch(progressProvider) : null;

    final progress = realProgress ?? _demoProgress;
    final isDemo = realProgress == null;

    return Scaffold(
      body: SafeArea(
        child: _buildContent(context, progress, isDemo: isDemo),
      ),
    );
  }

  static final _demoProgress = UserProgress(
    totalSessions: 47,
    totalMinutes: 186,
    lastSessionDate: DateTime.now().subtract(const Duration(hours: 3)),
    badges: [
      'first_conversation',
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
      'Interviews', 'Presentations', 'Public Speaking',
      'Conversations', 'Debates', 'Storytelling',
    ];

    return List.generate(47, (i) {
      final daysAgo = (i * 1.9).toInt() + rng.nextInt(2);
      final cat = categories[rng.nextInt(categories.length)];
      final base = 55 + rng.nextInt(35);
      return SessionRecord(
        scenarioId: 'demo_$i',
        category: cat,
        overallScore: base,
        clarity: (base - 5 + rng.nextInt(15)).clamp(20, 100),
        confidence: (base - 8 + rng.nextInt(18)).clamp(20, 100),
        engagement: (base - 3 + rng.nextInt(12)).clamp(20, 100),
        relevance: (base + rng.nextInt(10)).clamp(20, 100),
        durationSeconds: 120 + rng.nextInt(300),
        date: now.subtract(Duration(days: daysAgo, hours: rng.nextInt(12))),
      );
    });
  }

  // Returns (label, emoji, color) based on avg score
  static (String, String, Color) _speechLevel(double avg) {
    if (avg >= 85) return ('Expert Speaker', '🏆', AppColors.gold);
    if (avg >= 75) return ('Strong Speaker', '🔥', AppColors.success);
    if (avg >= 60) return ('Good Speaker', '⭐', AppColors.primary);
    if (avg >= 40) return ('Getting Better', '📈', AppColors.skyBlue);
    return ('Just Starting', '🌱', const Color(0xFF4CAF50));
  }

  static String? _nextLevelHint(double avg) {
    if (avg >= 85) return "You're at the top — keep pushing higher!";
    if (avg >= 75) return 'Score 85+ avg to reach Expert Speaker';
    if (avg >= 60) return 'Score 75+ avg to reach Strong Speaker';
    if (avg >= 40) return 'Score 60+ avg to reach Good Speaker';
    return null;
  }

  Widget _buildContent(BuildContext context, UserProgress progress,
      {bool isDemo = false}) {
    final sessions = progress.sessionHistory;
    final avgScore = sessions.isNotEmpty
        ? sessions.map((s) => s.overallScore).reduce((a, b) => a + b) /
            sessions.length
        : 0.0;

    final (label, emoji, levelColor) = _speechLevel(avgScore);
    final nextHint = _nextLevelHint(avgScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Header
          Text('Progress', style: AppTypography.headlineLarge())
              .animate().fadeIn(duration: 400.ms),

          // Demo banner
          if (isDemo) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sample data — complete sessions to see your real stats',
                      style:
                          AppTypography.labelSmall(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── Level card ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: levelColor.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji  $label',
                  style: AppTypography.headlineMedium(color: levelColor),
                ),
                const SizedBox(height: 6),
                Text(
                  sessions.isEmpty
                      ? 'Complete your first session to get your score'
                      : '${sessions.length} sessions completed · avg ${avgScore.toStringAsFixed(0)}/100',
                  style: AppTypography.bodySmall(
                      color: context.textSecondary),
                ),
                if (nextHint != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded,
                          size: 14, color: context.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        nextHint,
                        style: AppTypography.labelSmall(
                            color: context.textTertiary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
          const SizedBox(height: 14),

          // ── 2 mini stats ──────────────────────────────────────────────────
          Row(
            children: [
              _MiniStat(
                icon: Icons.mic_rounded,
                value: '${sessions.length}',
                label: 'Sessions',
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                icon: Icons.timer_rounded,
                value: '${progress.totalMinutes}m',
                label: 'Practice',
                color: AppColors.skyBlue,
              ),
            ],
          ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
          const SizedBox(height: 20),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Mini Stat ───────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
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

// ─── Skeleton ────────────────────────────────────────────────────────────────

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
          const SizedBox(height: 24),
          Skeleton(height: 120, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 14),
          Skeleton(height: 80, borderRadius: BorderRadius.circular(16)),
          const SizedBox(height: 20),
          Skeleton(height: 100, borderRadius: BorderRadius.circular(16)),
        ],
      ),
    );
  }
}
