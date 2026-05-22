class AppConstants {
  AppConstants._();

  // App
  static const appName = 'Speechy AI';
  static const appTagline = 'Your AI Speaking Coach';

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 2);

  // Layout
  static const double paddingXS = 4;
  static const double paddingSM = 8;
  static const double paddingMD = 16;
  static const double paddingLG = 24;
  static const double paddingXL = 32;

  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 24;
  static const double radiusFull = 999;

  // Bottom nav
  static const double bottomNavHeight = 80;

  // Practice categories
  static const List<String> categories = [
    'Presentations',
    'Interviews',
    'Public Speaking',
    'Conversations',
    'Debates',
    'Storytelling',
    'Phone Anxiety',
    'Dating & Social',
    'Conflict & Boundaries',
    'Social Situations',
  ];

  // SharedPreferences keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyThemeMode = 'theme_mode';
  static const String keyDefaultVoice = 'default_voice';
  static const String keyDefaultDuration = 'default_duration_minutes';
  static const String keyAutoScore = 'auto_score';
  static const String keyPracticeReminders = 'practice_reminders';
  static const String keyReminderTimeHour = 'reminder_time_hour';
  static const String keyReminderTimeMinute = 'reminder_time_minute';
  static const String keyStreakReminders = 'streak_reminders';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';
  static const String feedbackCollection = 'feedback';

}
