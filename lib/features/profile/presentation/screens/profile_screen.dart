import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/features/history/presentation/providers/session_history_provider.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';
import 'package:speech_coach/features/assessment/data/assessment_data.dart';
import 'package:speech_coach/features/paywall/domain/track_tier.dart';
import 'package:speech_coach/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:speech_coach/shared/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionHistoryProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final progress = ref.watch(progressProvider);
    final historyState = ref.watch(sessionHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 1. Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: AppTypography.headlineLarge(),
                  ),
                  Tappable(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: context.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),

              // 2. Identity
              authState.when(
                data: (user) {
                  final name = user?.displayName ?? 'User';
                  final photoUrl = user?.photoURL;
                  return Center(
                    child: Column(
                      children: [
                        UserAvatar(
                          photoUrl: photoUrl,
                          name: name,
                          radius: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: AppTypography.headlineMedium()),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text('Error loading profile: $e'),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Stats
              Row(
                children: [
                  if (progress.streak > 0) ...[
                    _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      value: '${progress.streak}',
                      label: 'Day Streak',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                  ],
                  _StatCard(
                    icon: Icons.mic_rounded,
                    value: '${progress.totalSessions}',
                    label: 'Sessions',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.timer_rounded,
                    value: '${progress.totalMinutes}',
                    label: 'Minutes',
                    color: AppColors.primary,
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 24),

              // Unlocked Tracks
              _UnlockedTracksSection(),

              // Recent Sessions
              if (historyState.status == SessionHistoryStatus.loaded) ...[
                if (historyState.sessions.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Sessions',
                          style: AppTypography.titleMedium()),
                      Tappable(
                        onTap: () => context.push('/history'),
                        child: Text(
                          'See All',
                          style: AppTypography.labelMedium(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...historyState.sessions.take(3).map(
                        (session) => _RecentSessionTile(session: session),
                      ),
                ] else ...[
                  Text('Recent Sessions',
                      style: AppTypography.titleMedium()),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? context.card,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: context.divider, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.mic_none_rounded,
                            size: 32, color: context.textTertiary),
                        const SizedBox(height: 8),
                        Text(
                          'No sessions yet',
                          style: AppTypography.titleMedium(
                              color: context.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start practicing to see your history here',
                          style: AppTypography.bodySmall(
                              color: context.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.divider, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleLarge(color: color)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockedTracksSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(subscriptionProvider.select((s) => s.purchasedTiers));
    if (tiers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unlocked Tracks', style: AppTypography.titleMedium()),
        const SizedBox(height: 8),
        ...tiers.entries.map((e) {
          final trackId = e.key;
          final tier = e.value;
          final title = generatePlanFromTemplateId(trackId).title;
          final isUltra = tier == TrackTier.ultra;
          final isPro = tier == TrackTier.pro;
          final badgeColor = isUltra
              ? const Color(0xFF7C3AED)
              : isPro
                  ? const Color(0xFFD97706)
                  : AppColors.primary;
          final badgeLabel = tier.displayName;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.divider, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUltra
                        ? Icons.diamond_rounded
                        : isPro
                            ? Icons.star_rounded
                            : Icons.lock_open_rounded,
                    color: badgeColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: AppTypography.bodyMedium()),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    badgeLabel,
                    style: AppTypography.labelSmall(color: badgeColor)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }
}

class _RecentSessionTile extends StatelessWidget {
  final SessionHistoryEntry session;

  const _RecentSessionTile({required this.session});

  Color get _scoreColor {
    final score = session.overallScore ?? 0;
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final score = session.overallScore ?? 0;
    return Tappable(
      onTap: () => context.push('/history/${session.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.divider, width: 2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
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
                    style: AppTypography.labelMedium(color: _scoreColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
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
                  Text(
                    _formatDate(session.createdAt),
                    style: AppTypography.labelSmall(
                      color: context.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
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
}

