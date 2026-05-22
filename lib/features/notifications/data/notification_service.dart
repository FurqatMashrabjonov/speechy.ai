import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'speechy_reminders';
  static const _channelName = 'Speechy Reminders';

  // Notification IDs
  static const _idDaily = 100;
  static const _idStreakWarning = 101;
  static const _idStepUnlocked = 102;
  static const _idWeeklySummary = 103;
  static const _idReEngagement = 104;

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  // ── 1. Daily reminder — 9am every day ──────────────────────────────────────
  static Future<void> scheduleDailyReminder({
    required int currentStep,
    required String trackTitle,
  }) async {
    await _plugin.cancel(_idDaily);
    final scheduled = _nextTimeAt(9, 0);
    final stepText = currentStep > 0 ? 'Step $currentStep' : 'your first step';

    await _schedule(
      id: _idDaily,
      title: 'Ready to practice?',
      body: '$stepText of $trackTitle is waiting. 10 min to level up.',
      scheduledDate: scheduled,
      repeat: true,
    );
  }

  // ── 2. Streak warning — 8pm today if user hasn't practiced ─────────────────
  static Future<void> scheduleStreakWarning(int streak) async {
    await _plugin.cancel(_idStreakWarning);
    if (streak <= 0) return;

    final now = tz.TZDateTime.now(tz.local);
    final todayAt8pm = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, 20, 0,
    );
    if (todayAt8pm.isBefore(now)) return; // 8pm already passed

    await _schedule(
      id: _idStreakWarning,
      title: '🔥 Don\'t break your $streak-day streak!',
      body: 'Just 1 session keeps your streak alive. You\'ve got this.',
      scheduledDate: todayAt8pm,
      repeat: false,
    );
  }

  // ── 3. Step unlocked — fired immediately after passing a step ──────────────
  static Future<void> scheduleStepUnlocked(String completedStep) async {
    await _plugin.cancel(_idStepUnlocked);
    await _plugin.show(
      _idStepUnlocked,
      'Next step unlocked! 🎉',
      'You passed "$completedStep". Keep the momentum going.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  // ── 4. Weekly summary — Sunday 7pm ────────────────────────────────────────
  static Future<void> scheduleWeeklySummary({
    required int sessionsThisWeek,
    required int xpThisWeek,
    required int streak,
  }) async {
    await _plugin.cancel(_idWeeklySummary);
    final now = tz.TZDateTime.now(tz.local);
    // Next Sunday at 19:00
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final sunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + (daysUntilSunday == 0 ? 7 : daysUntilSunday),
      19,
      0,
    );

    final xpText = xpThisWeek > 0 ? '+$xpThisWeek XP' : 'new XP';
    await _schedule(
      id: _idWeeklySummary,
      title: 'Your week in review',
      body:
          '$sessionsThisWeek sessions · $xpText · 🔥 $streak streak. Keep it up!',
      scheduledDate: sunday,
      repeat: false,
    );
  }

  // ── 5. Re-engagement — when 3+ days inactive ──────────────────────────────
  static Future<void> scheduleReEngagement(String trackTitle) async {
    await _plugin.cancel(_idReEngagement);
    final in3Days = tz.TZDateTime.now(tz.local).add(const Duration(days: 3));
    final at9am = tz.TZDateTime(
      tz.local, in3Days.year, in3Days.month, in3Days.day, 9, 0,
    );

    await _schedule(
      id: _idReEngagement,
      title: 'Your track misses you',
      body: 'Pick up where you left off in $trackTitle. It only takes 10 min.',
      scheduledDate: at9am,
      repeat: false,
    );
  }

  // ── Legacy: streak reminder (kept for backwards compat) ────────────────────
  static Future<void> scheduleStreakReminder(int streak, {int hour = 19, int minute = 0}) async {
    await scheduleStreakWarning(streak);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> cancelStreakWarning() async {
    await _plugin.cancel(_idStreakWarning);
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  static tz.TZDateTime _nextTimeAt(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required bool repeat,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Speechy practice reminders',
            importance: Importance.high,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            repeat ? DateTimeComponents.time : null,
      );
    } catch (e) {
      debugPrint('NotificationService: failed to schedule $id: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
