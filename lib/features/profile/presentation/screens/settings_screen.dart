import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/profile/presentation/providers/settings_provider.dart';
import 'package:speech_coach/shared/providers/theme_provider.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

final micQualityProvider = StateProvider<String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return prefs.getString('mic_quality') ?? 'High';
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _curatedVoices = [
    'Puck',
    'Kore',
    'Aoede',
    'Fenrir',
    'Gacrux',
    'Achird',
    'Sulafat',
    'Alnilam',
    'Zephyr',
    'Schedar',
  ];

  static const _durationOptions = [1, 3, 5, 10];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final micQuality = ref.watch(micQualityProvider);
    final defaultVoice = ref.watch(defaultVoiceProvider);
    final defaultDuration = ref.watch(defaultDurationProvider);
    final autoScore = ref.watch(autoScoreProvider);
    final practiceReminders = ref.watch(practiceRemindersProvider);
    final reminderHour = ref.watch(reminderTimeHourProvider);
    final reminderMinute = ref.watch(reminderTimeMinuteProvider);
    final streakReminders = ref.watch(streakRemindersProvider);

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
          // --- Practice ---
          _SettingsSection(
            title: 'Practice',
            children: [
              ListTile(
                leading: _icon(Icons.record_voice_over_rounded,
                    AppColors.primary),
                title: const Text('Default AI Voice'),
                subtitle: Text(defaultVoice),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textTertiary),
                onTap: () =>
                    _showVoicePicker(context, ref, defaultVoice),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading:
                    _icon(Icons.timer_outlined, AppColors.skyBlue),
                title: const Text('Conversation Length'),
                subtitle: Text('$defaultDuration min'),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textTertiary),
                onTap: () => _showDurationPicker(
                    context, ref, defaultDuration),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading:
                    _icon(Icons.auto_awesome_rounded, AppColors.gold),
                title: const Text('Auto-score after session'),
                trailing: Switch.adaptive(
                  value: autoScore,
                  activeTrackColor: AppColors.success,
                  onChanged: (v) async {
                    ref.read(autoScoreProvider.notifier).state = v;
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setBool('auto_score', v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Notifications ---
          _SettingsSection(
            title: 'Notifications',
            children: [
              ListTile(
                leading: _icon(
                    Icons.notifications_outlined, AppColors.secondary),
                title: const Text('Practice Reminders'),
                trailing: Switch.adaptive(
                  value: practiceReminders,
                  activeTrackColor: AppColors.success,
                  onChanged: (v) async {
                    ref.read(practiceRemindersProvider.notifier).state =
                        v;
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setBool('practice_reminders', v);
                  },
                ),
              ),
              if (practiceReminders) ...[
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading:
                      _icon(Icons.access_time_rounded, AppColors.primary),
                  title: const Text('Reminder Time'),
                  subtitle: Text(
                    '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}',
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: context.textTertiary),
                  onTap: () => _showTimePicker(
                      context, ref, reminderHour, reminderMinute),
                ),
              ],
              const Divider(height: 1, indent: 60),
              ListTile(
                leading: _icon(Icons.local_fire_department_rounded,
                    AppColors.primary),
                title: const Text('Streak Reminders'),
                trailing: Switch.adaptive(
                  value: streakReminders,
                  activeTrackColor: AppColors.success,
                  onChanged: (v) async {
                    ref.read(streakRemindersProvider.notifier).state =
                        v;
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setBool('streak_reminders', v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                  activeTrackColor: AppColors.success,
                  onChanged: (_) {
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Audio ---
          _SettingsSection(
            title: 'Audio',
            children: [
              ListTile(
                leading: _icon(
                    Icons.mic_outlined, AppColors.secondary),
                title: const Text('Microphone Quality'),
                subtitle: Text(micQuality),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textTertiary),
                onTap: () =>
                    _showMicQualitySheet(context, ref, micQuality),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Support ---
          _SettingsSection(
            title: 'Support',
            children: [
              ListTile(
                leading: _icon(
                    Icons.help_outline_rounded, AppColors.secondary),
                title: const Text('Help & Support'),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textTertiary),
                onTap: () => launchUrl(
                  Uri.parse('mailto:support@speechyai.app'),
                ),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading:
                    _icon(Icons.star_outline_rounded, AppColors.gold),
                title: const Text('Rate the App'),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textTertiary),
                onTap: () => launchUrl(
                  Uri.parse(
                      'https://apps.apple.com/app/speechy-ai'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading: _icon(
                    Icons.share_rounded, AppColors.primary),
                title: const Text('Share with Friends'),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textTertiary),
                onTap: () => launchUrl(
                  Uri.parse(
                      'https://apps.apple.com/app/speechy-ai'),
                  mode: LaunchMode.externalApplication,
                ),
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
                    Icons.description_outlined, AppColors.gold),
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
                    Icons.gavel_outlined, AppColors.primaryDark),
                title: const Text('Terms of Service'),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textTertiary),
                onTap: () => launchUrl(
                  Uri.parse('https://speechyai.app/terms'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading: _icon(
                    Icons.info_outline_rounded, AppColors.skyBlue),
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

  void _showVoicePicker(
      BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(context),
              const SizedBox(height: 16),
              Text('Default AI Voice',
                  style: AppTypography.titleMedium()),
              const SizedBox(height: 8),
              for (final voice in _curatedVoices)
                ListTile(
                  title: Text(voice),
                  trailing: current == voice
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () async {
                    ref.read(defaultVoiceProvider.notifier).state =
                        voice;
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setString('default_voice', voice);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDurationPicker(
      BuildContext context, WidgetRef ref, int current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(context),
              const SizedBox(height: 16),
              Text('Conversation Length',
                  style: AppTypography.titleMedium()),
              const SizedBox(height: 8),
              for (final mins in _durationOptions)
                ListTile(
                  title: Text('$mins minute${mins > 1 ? 's' : ''}'),
                  trailing: current == mins
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () async {
                    ref.read(defaultDurationProvider.notifier).state =
                        mins;
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setInt(
                        'default_duration_minutes', mins);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMicQualitySheet(
      BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(context),
              const SizedBox(height: 16),
              Text('Microphone Quality',
                  style: AppTypography.titleMedium()),
              const SizedBox(height: 8),
              for (final quality in ['Low', 'Medium', 'High'])
                ListTile(
                  title: Text(quality),
                  trailing: current == quality
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () async {
                    ref.read(micQualityProvider.notifier).state =
                        quality;
                    final prefs = ref.read(sharedPreferencesProvider);
                    await prefs.setString('mic_quality', quality);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context, WidgetRef ref,
      int currentHour, int currentMinute) async {
    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: currentHour, minute: currentMinute),
    );
    if (time != null) {
      ref.read(reminderTimeHourProvider.notifier).state = time.hour;
      ref.read(reminderTimeMinuteProvider.notifier).state =
          time.minute;
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setInt('reminder_time_hour', time.hour);
      await prefs.setInt('reminder_time_minute', time.minute);
    }
  }

  Widget _sheetHandle(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: context.divider,
        borderRadius: BorderRadius.circular(2),
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
