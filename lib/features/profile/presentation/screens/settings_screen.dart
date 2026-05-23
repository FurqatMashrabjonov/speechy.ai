import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/auth/presentation/providers/auth_provider.dart';
import 'package:speech_coach/shared/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final email = authState.whenOrNull(data: (user) => user?.email) ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Appearance ---
          _SettingsSection(
            title: 'Appearance',
            children: [
              ListTile(
                leading:
                    _icon(Icons.dark_mode_outlined, AppColors.primary),
                title: const Text('Dark Mode'),
                trailing: Switch.adaptive(
                  value: themeMode == ThemeMode.dark,
                  activeTrackColor: AppColors.primary,
                  onChanged: (_) {
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Account ---
          _SettingsSection(
            title: 'Account',
            children: [
              ListTile(
                leading: _icon(Icons.email_outlined, AppColors.primary),
                title: const Text('Email'),
                subtitle: Text(email),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading: _icon(Icons.logout_rounded, AppColors.error),
                title: Text(
                  'Log Out',
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Legal ---
          _SettingsSection(
            title: 'Legal',
            children: [
              ListTile(
                leading: _icon(
                    Icons.description_outlined, AppColors.primary),
                title: const Text('Privacy Policy'),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textTertiary),
                onTap: () => launchUrl(
                  Uri.parse('https://speechyai.app/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading: _icon(
                    Icons.info_outline_rounded, AppColors.primary),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
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

  void _confirmLogout(BuildContext context, WidgetRef ref) {
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
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium(
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
