import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/history/data/session_history_repository.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';
import 'package:speech_coach/shared/widgets/coach_tip_card.dart';
import 'package:speech_coach/shared/widgets/progress_bar.dart';
import 'package:speech_coach/shared/widgets/score_ring.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

final _sessionDetailProvider =
    FutureProvider.family<SessionHistoryEntry?, String>((ref, id) async {
  final repository = ref.read(sessionHistoryRepositoryProvider);
  return repository.getSession(id);
});

class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

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
                  Text('Could not load session', style: AppTypography.headlineSmall()),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(color: context.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Tappable(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Go Back', style: AppTypography.labelLarge(color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (session) {
            if (session == null) {
              return Center(
                child: Text('Session not found', style: AppTypography.bodyMedium(color: context.textSecondary)),
              );
            }
            return _buildDetail(context, session);
          },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, SessionHistoryEntry session) {
    final score = session.overallScore ?? 0;

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
              const Spacer(),
              Text('Session Feedback', style: AppTypography.titleMedium()),
              const Spacer(),
              const SizedBox(width: 24),
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

                // Category + date
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(session.category, style: AppTypography.labelSmall(color: AppColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFullDate(session.createdAt),
                      style: AppTypography.bodySmall(color: context.textTertiary),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),

                // Score Ring
                ScoreRing(score: score, size: 160, strokeWidth: 6),
                const SizedBox(height: 8),

                // Score label
                Text(
                  _getScoreLabel(score),
                  style: AppTypography.headlineMedium(color: _getScoreColor(score)),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 24),

                // Breakdown card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.divider, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Breakdown', style: AppTypography.titleMedium()),
                      const SizedBox(height: 16),
                      ProgressBar(
                        value: (session.clarity ?? 0) / 100,
                        label: 'Clarity',
                        trailingText: '${session.clarity ?? 0}%',
                        icon: Icons.waves_rounded,
                        delay: const Duration(milliseconds: 50),
                      ),
                      const SizedBox(height: 14),
                      ProgressBar(
                        value: (session.confidence ?? 0) / 100,
                        label: 'Confidence',
                        trailingText: '${session.confidence ?? 0}%',
                        icon: Icons.shield_rounded,
                        delay: const Duration(milliseconds: 150),
                      ),
                      const SizedBox(height: 14),
                      ProgressBar(
                        value: (session.engagement ?? 0) / 100,
                        label: 'Engagement',
                        trailingText: '${session.engagement ?? 0}%',
                        icon: Icons.people_rounded,
                        delay: const Duration(milliseconds: 250),
                      ),
                      const SizedBox(height: 14),
                      ProgressBar(
                        value: (session.relevance ?? 0) / 100,
                        label: 'Relevance',
                        trailingText: '${session.relevance ?? 0}%',
                        icon: Icons.track_changes_rounded,
                        delay: const Duration(milliseconds: 350),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),

                // Summary as coach tip
                if (session.summary != null && session.summary!.isNotEmpty) ...[
                  CoachTipCard(tip: session.summary!).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                ],

                // Strengths
                if (session.strengths != null && session.strengths!.isNotEmpty) ...[
                  _FeedbackList(
                    title: 'Strengths',
                    items: session.strengths!,
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                ],

                // Improvements
                if (session.improvements != null && session.improvements!.isNotEmpty) ...[
                  _FeedbackList(
                    title: 'Areas to Improve',
                    items: session.improvements!,
                    icon: Icons.arrow_upward_rounded,
                    iconColor: AppColors.warning,
                  ),
                  const SizedBox(height: 16),
                ],

                // Transcript
                if (session.transcript.isNotEmpty) ...[
                  _TranscriptSection(transcript: session.transcript)
                      .animate()
                      .fadeIn(duration: 400.ms),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent Work!';
    if (score >= 80) return 'Great Job!';
    if (score >= 70) return 'Good Work!';
    if (score >= 50) return 'Keep Going!';
    return 'Keep Practicing!';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} · $h:$m';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: AppTypography.titleMedium()),
        ),
        ...List.generate(items.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: context.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    items[index],
                    style: AppTypography.bodyMedium(color: context.textPrimary)
                        .copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: (index * 100).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOut);
        }),
      ],
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
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Transcript', style: AppTypography.titleMedium()),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                children: lines.map((line) {
                  final isUser = line.startsWith('You:') || line.startsWith('User:');
                  final isAi = line.startsWith('AI:');
                  final text = isUser
                      ? (line.startsWith('User:')
                          ? line.substring(5)
                          : line.substring(4))
                          .trim()
                      : isAi
                          ? line.substring(3).trim()
                          : line;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUser || isAi)
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 8, top: 1),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                              size: 14,
                              color: isUser ? AppColors.primary : AppColors.accent,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            text,
                            style: AppTypography.bodySmall(color: context.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
