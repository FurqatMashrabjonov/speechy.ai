import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/core/analytics/analytics_service.dart';
import 'package:speech_coach/features/assessment/data/assessment_repository.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/feedback/domain/feedback_entity.dart';
import 'package:speech_coach/features/notifications/data/notification_service.dart';
import 'package:speech_coach/features/progress/data/progress_remote_repository.dart';
import 'package:speech_coach/features/progress/data/progress_repository.dart';
import 'package:speech_coach/features/progress/domain/progress_entity.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ProgressRepository(prefs);
});

class ProgressNotifier extends StateNotifier<UserProgress> {
  final ProgressRepository _repository;
  final ProgressRemoteRepository _remoteRepository;
  final AssessmentRepository _assessmentRepository;

  ProgressNotifier(this._repository, this._remoteRepository, this._assessmentRepository)
      : super(const UserProgress()) {
    _loadAndSync();
  }

  Future<void> _loadAndSync() async {
    // Load local first (fast — always works)
    final local = _repository.load();
    state = local;

    // Schedule re-engagement if inactive 3+ days
    if (local.lastSessionDate != null) {
      final daysSinceLast =
          DateTime.now().difference(local.lastSessionDate!).inDays;
      if (daysSinceLast >= 3) {
        final trackTitle = _assessmentRepository.getLearningPlan()?.title ?? _planTitle(local);
        NotificationService.scheduleReEngagement(trackTitle);
      }
    }

    // Then try to merge with cloud (with timeout so it doesn't hang)
    try {
      final remote = await _remoteRepository
          .load()
          .timeout(const Duration(seconds: 5));
      if (remote != null) {
        final merged = ProgressRemoteRepository.merge(local, remote);
        state = merged;
        await _repository.save(merged);
        // Push merged back to cloud in background
        _remoteRepository.save(merged).timeout(
          const Duration(seconds: 5),
        ).catchError((_) {});
      } else {
        // No remote data yet — push local to cloud in background
        _remoteRepository.save(local).timeout(
          const Duration(seconds: 5),
        ).catchError((_) {});
      }
    } catch (_) {
      // Offline or Firestore unavailable — just use local
      debugPrint('ProgressNotifier: cloud sync skipped (offline/error)');
    }
  }

  Future<void> addSession(ConversationFeedback feedback) async {
    debugPrint('ProgressNotifier.addSession: score=${feedback.overallScore}');

    // Calculate streak (with streak freeze support)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreak = state.streak;
    int newStreakFreezes = state.streakFreezes;
    DateTime? newLastFreezeDate = state.lastFreezeDate;

    if (state.lastSessionDate != null) {
      final lastDate = DateTime(
        state.lastSessionDate!.year,
        state.lastSessionDate!.month,
        state.lastSessionDate!.day,
      );
      final diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        newStreak = state.streak + 1;
      } else if (diff == 2 && state.streakFreezes > 0) {
        // Streak freeze: missed exactly 1 day with freeze available
        newStreak = state.streak + 1;
        newStreakFreezes = state.streakFreezes - 1;
        newLastFreezeDate = today;
      } else if (diff > 1) {
        newStreak = 1;
      }
      // diff == 0 means same day, keep streak
    } else {
      newStreak = 1;
    }

    debugPrint('ProgressNotifier.addSession: streak=$newStreak '
        '(was ${state.streak}), longest=${state.longestStreak}, '
        'sessions=${state.totalSessions + 1}');

    final record = SessionRecord(
      scenarioId: feedback.scenarioId,
      category: feedback.category,
      overallScore: feedback.overallScore,
      clarity: feedback.clarity,
      confidence: feedback.confidence,
      engagement: feedback.engagement,
      relevance: feedback.relevance,
      durationSeconds: feedback.durationSeconds,
      date: now,
    );

    // Check for new badges
    final newBadges = List<String>.from(state.badges);
    if (state.totalSessions == 0 && !newBadges.contains('first_conversation')) {
      newBadges.add('first_conversation');
    }
    if (newStreak >= 5 && !newBadges.contains('5_day_streak')) {
      newBadges.add('5_day_streak');
      AnalyticsService.instance.logStreakMilestone(streak: newStreak);
    }
    if (newStreak >= 10 && !newBadges.contains('10_day_streak')) {
      newBadges.add('10_day_streak');
      AnalyticsService.instance.logStreakMilestone(streak: newStreak);
    }
    if (feedback.clarity >= 100 && !newBadges.contains('perfect_clarity')) {
      newBadges.add('perfect_clarity');
    }
    if (feedback.overallScore >= 90 && !newBadges.contains('star_performer')) {
      newBadges.add('star_performer');
    }
    if (state.totalSessions + 1 >= 10 && !newBadges.contains('dedicated_10')) {
      newBadges.add('dedicated_10');
    }
    if (state.totalSessions + 1 >= 50 && !newBadges.contains('dedicated_50')) {
      newBadges.add('dedicated_50');
    }

    // Check category-specific badges
    final categorySessions = state.sessionHistory
            .where((s) => s.category == feedback.category)
            .length +
        1;
    final categoryBadge =
        '${feedback.category.toLowerCase().replaceAll(' ', '_')}_5';
    if (categorySessions >= 5 && !newBadges.contains(categoryBadge)) {
      newBadges.add(categoryBadge);
    }

    state = state.copyWith(
      streak: newStreak,
      longestStreak:
          newStreak > state.longestStreak ? newStreak : state.longestStreak,
      totalSessions: state.totalSessions + 1,
      totalMinutes:
          state.totalMinutes + (feedback.durationSeconds / 60).ceil(),
      lastSessionDate: now,
      badges: newBadges,
      sessionHistory: [...state.sessionHistory, record],
      streakFreezes: newStreakFreezes,
      lastFreezeDate: newLastFreezeDate,
    );

    await _repository.save(state);

    // Sync to Firestore in background (non-blocking — local save above is the source of truth)
    _remoteRepository.save(state).timeout(
      const Duration(seconds: 5),
      onTimeout: () => debugPrint('ProgressNotifier: Firestore sync timed out (non-critical)'),
    ).catchError((e) {
      debugPrint('ProgressNotifier: Firestore sync failed (non-critical): $e');
    });

    // Cancel streak warning — user practiced today
    await NotificationService.cancelStreakWarning();

    // Schedule tomorrow's streak warning (8pm) and daily reminder (9am)
    await NotificationService.scheduleStreakWarning(newStreak);

    // Schedule weekly summary on Sundays
    final now2 = DateTime.now();
    if (now2.weekday == DateTime.sunday) {
      final weekSessions = state.sessionHistory
          .where((s) {
            final diff = now2.difference(s.date).inDays;
            return diff < 7;
          })
          .length;
      await NotificationService.scheduleWeeklySummary(
        sessionsThisWeek: weekSessions,
        streak: newStreak,
      );
    }
  }

  String _planTitle(UserProgress p) {
    if (p.sessionHistory.isEmpty) return 'your track';
    final cat = p.sessionHistory.last.category;
    return cat.isNotEmpty ? cat : 'your track';
  }

  /// Grants a streak freeze (e.g., for Pro users monthly)
  Future<void> grantStreakFreeze() async {
    state = state.copyWith(
      streakFreezes: state.streakFreezes + 1,
    );
    await _repository.save(state);
    _remoteRepository.save(state).timeout(
      const Duration(seconds: 5),
    ).catchError((_) {});
  }

  /// Returns true if daily goal was just completed on this session
  bool get dailyGoalJustCompleted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todaySessions = state.sessionHistory
        .where((s) {
          final d = DateTime(s.date.year, s.date.month, s.date.day);
          return d == today;
        })
        .length;
    return todaySessions == 1; // Exactly 1 means just completed
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, UserProgress>((ref) {
  final repository = ref.read(progressRepositoryProvider);
  final remoteRepository = ref.read(progressRemoteRepositoryProvider);
  final assessmentRepository = ref.read(assessmentRepositoryProvider);
  return ProgressNotifier(repository, remoteRepository, assessmentRepository);
});
