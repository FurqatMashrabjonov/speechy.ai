import 'package:home_widget/home_widget.dart';
import 'package:speech_coach/features/progress/domain/progress_entity.dart';

class WidgetService {
  static const _androidStatsWidget = 'StatsWidgetProvider';
  static const _androidPracticeWidget = 'PracticeWidgetProvider';
  static const _androidActivityWidget = 'ActivityWidgetProvider';

  static Future<void> updateWidgetData(UserProgress progress) async {
    try {
      final activityGrid = _buildActivityGrid(progress.sessionHistory);

      await Future.wait([
        HomeWidget.saveWidgetData<int>('streak', progress.streak),
        HomeWidget.saveWidgetData<int>('level', progress.level),
        HomeWidget.saveWidgetData<String>('levelTitle', progress.levelTitle),
        HomeWidget.saveWidgetData<int>('totalXp', progress.totalXp),
        HomeWidget.saveWidgetData<int>('totalSessions', progress.totalSessions),
        HomeWidget.saveWidgetData<double>('xpProgress', progress.levelProgress),
        HomeWidget.saveWidgetData<int>('xpForNext', progress.xpForNextLevel),
        HomeWidget.saveWidgetData<String>('activityGrid', activityGrid),
      ]);

      await Future.wait([
        HomeWidget.updateWidget(androidName: _androidStatsWidget),
        HomeWidget.updateWidget(androidName: _androidPracticeWidget),
        HomeWidget.updateWidget(androidName: _androidActivityWidget),
      ]);
    } catch (_) {
      // Home widget not configured — non-critical, skip silently
    }
  }

  /// Builds a comma-separated string of 35 intensity levels (0-3).
  /// Layout: row-major — cell index = dayOfWeek * 5 + weekIndex
  /// dayOfWeek: 0=Mon, 1=Tue, ..., 6=Sun
  /// weekIndex: 0=oldest week, 4=current week
  static String _buildActivityGrid(List<SessionRecord> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Align to Monday of the oldest week (5 weeks back)
    final daysBack = 34 + (today.weekday - 1); // weekday: 1=Mon
    final startDate = today.subtract(Duration(days: daysBack));

    // Count sessions per date
    final counts = <DateTime, int>{};
    for (final s in sessions) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff <= daysBack) {
        counts[d] = (counts[d] ?? 0) + 1;
      }
    }

    // Build 35-cell grid in row-major order
    // cell[dayOfWeek * 5 + weekIndex]
    final grid = List<int>.filled(35, 0);

    var current = startDate;
    while (!current.isAfter(today)) {
      final daysSinceStart = current.difference(startDate).inDays;
      final weekIndex = daysSinceStart ~/ 7;
      final dayOfWeek = daysSinceStart % 7; // 0=Mon since we aligned to Monday

      if (weekIndex < 5 && dayOfWeek < 7) {
        final cellIndex = dayOfWeek * 5 + weekIndex;
        final count = counts[current] ?? 0;
        // Map count to level: 0=none, 1=low, 2=med, 3=high
        final level = count == 0
            ? 0
            : count == 1
                ? 1
                : count == 2
                    ? 2
                    : 3;
        if (cellIndex < 35) {
          grid[cellIndex] = level;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return grid.join(',');
  }
}
