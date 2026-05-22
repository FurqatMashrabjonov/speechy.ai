import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/history/presentation/providers/session_history_provider.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class SessionHistoryScreen extends ConsumerStatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  ConsumerState<SessionHistoryScreen> createState() =>
      _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends ConsumerState<SessionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionHistoryProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Tappable(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Session History',
                    style: AppTypography.headlineSmall(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: switch (state.status) {
                SessionHistoryStatus.idle ||
                SessionHistoryStatus.loading =>
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                SessionHistoryStatus.error => _buildError(state.error),
                SessionHistoryStatus.loaded =>
                  state.sessions.isEmpty
                      ? _buildEmpty()
                      : _buildSessionList(state.sessions),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions yet',
              style: AppTypography.headlineSmall(),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a practice session to see your history here',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildError(String? error) {
    return Center(
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
              error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Tappable(
              onTap: () =>
                  ref.read(sessionHistoryProvider.notifier).loadSessions(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Try Again',
                  style: AppTypography.labelLarge(color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(List<SessionHistoryEntry> sessions) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(sessionHistoryProvider.notifier).loadSessions(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Dismissible(
            key: Key(session.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(session),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: AppColors.error,
              ),
            ),
            child: _SessionTile(session: session)
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: index * 50),
                  duration: 400.ms,
                )
                .slideX(begin: 0.05),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(SessionHistoryEntry session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Session?',
          style: AppTypography.headlineSmall(),
        ),
        content: Text(
          'This will permanently delete this session record.',
          style: AppTypography.bodyMedium(
            color: context.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(
                color: context.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: AppTypography.labelLarge(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(sessionHistoryProvider.notifier)
          .deleteSession(session.id);
      return true;
    }
    return false;
  }
}

class _SessionTile extends ConsumerWidget {
  final SessionHistoryEntry session;

  const _SessionTile({required this.session});

  Color get _scoreColor {
    final score = session.overallScore ?? 0;
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = session.overallScore ?? 0;
    return Tappable(
      onTap: () => context.push('/history/${session.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? context.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider, width: 0.5),
        ),
        child: Row(
          children: [
            // Score circle
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 3,
                      backgroundColor: context.divider,
                      color: _scoreColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$score',
                    style: AppTypography.titleMedium(color: _scoreColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Session info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.scenarioTitle,
                    style: AppTypography.titleMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.category,
                          style: AppTypography.labelSmall(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(session.createdAt),
                        style: AppTypography.labelSmall(
                          color: context.textTertiary,
                        ),
                      ),
                      if (session.durationSeconds > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(session.durationSeconds),
                          style: AppTypography.labelSmall(
                            color: context.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
