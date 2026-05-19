import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/history/data/session_history_repository.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';
import 'package:speech_coach/features/feedback/presentation/widgets/radar_chart.dart';
import 'package:speech_coach/features/feedback/presentation/widgets/score_bar.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

final _sessionDetailProvider =
    FutureProvider.family<SessionHistoryEntry?, String>((ref, id) async {
  final repository = ref.read(sessionHistoryRepositoryProvider);
  return repository.getSession(id);
});

class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSession = ref.watch(_sessionDetailProvider(sessionId));

    return Scaffold(
      body: SafeArea(
        child: asyncSession.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load session',
                    style: AppTypography.headlineSmall(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Tappable(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Go Back',
                        style:
                            AppTypography.labelLarge(color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (session) {
            if (session == null) {
              return Center(
                child: Text(
                  'Session not found',
                  style: AppTypography.bodyMedium(
                    color: context.textSecondary,
                  ),
                ),
              );
            }
            return _buildDetail(context, ref, session);
          },
        ),
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref,
    SessionHistoryEntry session,
  ) {
    return Column(
      children: [
        // App bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Tappable(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_rounded, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  session.scenarioTitle,
                  style: AppTypography.headlineSmall(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.category,
                        style: AppTypography.labelSmall(
                          color: AppColors.primary,
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 4),
                    // Date
                    Text(
                      _formatFullDate(session.createdAt),
                      style: AppTypography.bodySmall(
                        color: context.textTertiary,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 20),

                    // Overall score circle
                    _OverallScoreCircle(score: session.overallScore ?? 0)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 8),
                    Text(
                      '+${session.xpEarned ?? 0} XP',
                      style: AppTypography.titleMedium(
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: 24),

                    // Radar chart
                    ScoreRadarChart(
                      clarity: session.clarity ?? 0,
                      confidence: session.confidence ?? 0,
                      engagement: session.engagement ?? 0,
                      relevance: session.relevance ?? 0,
                      size: 220,
                    ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                    const SizedBox(height: 24),

                    // Score bars
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detailed Scores',
                            style: AppTypography.titleMedium(),
                          ),
                          const SizedBox(height: 12),
                          ScoreBar(
                            label: 'Clarity',
                            score: session.clarity ?? 0,
                            animationDelay: 0,
                          ),
                          ScoreBar(
                            label: 'Confidence',
                            score: session.confidence ?? 0,
                            animationDelay: 100,
                          ),
                          ScoreBar(
                            label: 'Engagement',
                            score: session.engagement ?? 0,
                            animationDelay: 200,
                          ),
                          ScoreBar(
                            label: 'Relevance',
                            score: session.relevance ?? 0,
                            animationDelay: 300,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                    const SizedBox(height: 16),

                    // Summary
                    if (session.summary != null && session.summary!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Summary',
                                style: AppTypography.titleMedium()),
                            const SizedBox(height: 8),
                            Text(
                              session.summary!,
                              style: AppTypography.bodyMedium(
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                    if (session.summary != null && session.summary!.isNotEmpty)
                      const SizedBox(height: 16),

                    // Strengths
                    if (session.strengths != null && session.strengths!.isNotEmpty)
                      _FeedbackList(
                        title: 'Strengths',
                        items: session.strengths!,
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.success,
                      ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                    if (session.strengths != null && session.strengths!.isNotEmpty)
                      const SizedBox(height: 16),

                    // Improvements
                    if (session.improvements != null && session.improvements!.isNotEmpty)
                      _FeedbackList(
                        title: 'Areas to Improve',
                        items: session.improvements!,
                        icon: Icons.arrow_upward_rounded,
                        iconColor: AppColors.warning,
                      ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
                    if (session.improvements != null && session.improvements!.isNotEmpty)
                      const SizedBox(height: 16),

                    // Transcript
                    if (session.transcript.isNotEmpty)
                      _TranscriptSection(transcript: session.transcript)
                          .animate()
                          .fadeIn(delay: 1000.ms, duration: 400.ms),
                    const SizedBox(height: 24),
                  ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $h:$m';
  }
}

class _OverallScoreCircle extends StatelessWidget {
  final int score;

  const _OverallScoreCircle({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String get _label {
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Great Job!';
    if (score >= 70) return 'Good Work';
    if (score >= 50) return 'Keep Going';
    return 'Keep Practicing';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: context.divider,
                  color: _color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: AppTypography.displayLarge(color: _color),
                  ),
                  Text(
                    '/100',
                    style: AppTypography.labelSmall(
                      color: context.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _label,
          style: AppTypography.titleLarge(color: _color),
        ),
      ],
    );
  }
}

class _FeedbackList extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;

  const _FeedbackList({
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium()),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptSection extends StatelessWidget {
  final String transcript;

  const _TranscriptSection({required this.transcript});

  @override
  Widget build(BuildContext context) {
    final lines = transcript
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Transcript', style: AppTypography.titleMedium()),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map((line) {
            final isUser = line.startsWith('You:');
            final isAi = line.startsWith('AI:');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser || isAi)
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : AppColors.lavender.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUser ? Icons.person_rounded : Icons.auto_awesome,
                        size: 14,
                        color:
                            isUser ? AppColors.primary : AppColors.lavender,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      isUser
                          ? line.substring(4).trim()
                          : isAi
                              ? line.substring(3).trim()
                              : line,
                      style: AppTypography.bodyMedium(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
