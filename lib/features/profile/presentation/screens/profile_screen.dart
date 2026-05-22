import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/core/extensions/string_extensions.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/features/history/presentation/providers/session_history_provider.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';

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
                  final email = user?.email ?? '';

                  return Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.14),
                                child: Text(
                                  name.initials,
                                  style: AppTypography.displaySmall(
                                      color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: AppTypography.headlineMedium()),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: AppTypography.bodySmall(
                            color: context.textSecondary,
                          ),
                        ),
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

              // 3. Stats 2x2 grid
              Row(
                children: [
                  _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    value: '${progress.streak}',
                    label: 'Day Streak',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
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
                    color: AppColors.skyBlue,
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 24),

              // 5. Badges section
              if (progress.badges.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFE5E5E5), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Badges',
                              style: AppTypography.titleMedium()),
                          const Spacer(),
                          Text(
                            '${progress.badges.length}',
                            style: AppTypography.labelMedium(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: progress.badges.map((badge) {
                          final label = _badgeLabels[badge] ??
                              badge.replaceAll('_', ' ');
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              label,
                              style: AppTypography.labelSmall(
                                  color: AppColors.gold),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
                const SizedBox(height: 20),
              ],

              // 7. Recent Sessions
              if (historyState.status == SessionHistoryStatus.loaded &&
                  historyState.sessions.isNotEmpty) ...[
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
                      (session) =>
                          _RecentSessionTile(session: session),
                    ),
                const SizedBox(height: 20),
              ],

              // 8. Account & Features
              _AccountSection(ref: ref),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static const _badgeLabels = <String, String>{
    'first_conversation': 'First Chat',
    '5_day_streak': '5-Day Streak',
    '10_day_streak': '10-Day Streak',
    'perfect_clarity': 'Perfect Clarity',
    'star_performer': 'Star Performer',
    'dedicated_10': '10 Sessions',
    'dedicated_50': '50 Sessions',
    'interviews_5': 'Interview Pro',
    'presentations_5': 'Presenter',
    'public_speaking_5': 'Public Speaker',
    'conversations_5': 'Conversationalist',
    'debates_5': 'Debater',
    'storytelling_5': 'Storyteller',
  };
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
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
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
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
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

class _AccountSection extends StatelessWidget {
  final WidgetRef ref;

  const _AccountSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final email = authState.whenOrNull(
          data: (user) => user?.email,
        ) ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: AppTypography.headlineSmall()),
        const SizedBox(height: 12),

        // Account info
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? context.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          ),
          child: Column(
            children: [
              ListTile(
                leading: _icon(Icons.email_outlined, AppColors.skyBlue),
                title: const Text('Email'),
                subtitle: Text(email),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Features

        // Account Actions
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? context.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          ),
          child: Column(
            children: [
              ListTile(
                leading: _icon(Icons.logout_rounded, AppColors.error),
                title: Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmLogout(context),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading:
                    _icon(Icons.delete_outline_rounded, AppColors.error),
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 260.ms, duration: 400.ms);
  }

  Widget _icon(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Please contact support@speechyai.app to delete your account.'),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
