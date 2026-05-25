import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _fa = FirebaseAnalytics.instance;

  // ── Screen tracking ──────────────────────────────────────────────────────────

  Future<void> logScreen(String screenName) =>
      _fa.logScreenView(screenName: screenName);

  // ── Assessment ───────────────────────────────────────────────────────────────

  Future<void> logAssessmentStarted() =>
      _fa.logEvent(name: 'assessment_started');

  Future<void> logAssessmentCompleted({required String trackId}) =>
      _fa.logEvent(name: 'assessment_completed', parameters: {'track_id': trackId});

  // ── Session ──────────────────────────────────────────────────────────────────

  Future<void> logSessionStarted({
    required String scenarioId,
    required String trackId,
    required int stepOrder,
  }) =>
      _fa.logEvent(name: 'session_started', parameters: {
        'scenario_id': scenarioId,
        'track_id': trackId,
        'step_order': stepOrder,
      });

  Future<void> logSessionCompleted({
    required String scenarioId,
    required String trackId,
    required int score,
    required int durationSeconds,
    required String result, // 'passed' | 'needs_retry'
  }) =>
      _fa.logEvent(name: 'session_completed', parameters: {
        'scenario_id': scenarioId,
        'track_id': trackId,
        'score': score,
        'duration_seconds': durationSeconds,
        'result': result,
      });

  // ── Paywall ──────────────────────────────────────────────────────────────────

  Future<void> logPaywallViewed({required String trackId}) =>
      _fa.logEvent(name: 'paywall_viewed', parameters: {'track_id': trackId});

  Future<void> logPurchaseInitiated({
    required String trackId,
    required String tier,
  }) =>
      _fa.logEvent(name: 'purchase_initiated', parameters: {
        'track_id': trackId,
        'tier': tier,
      });

  Future<void> logPurchaseCompleted({
    required String trackId,
    required String tier,
    required String price,
  }) =>
      _fa.logEvent(name: 'purchase_completed', parameters: {
        'track_id': trackId,
        'tier': tier,
        'price': price,
      });

  // ── Track ────────────────────────────────────────────────────────────────────

  Future<void> logTrackSelected({required String trackId}) =>
      _fa.logEvent(name: 'track_selected', parameters: {'track_id': trackId});

  Future<void> logTrackCompleted({required String trackId}) =>
      _fa.logEvent(name: 'track_completed', parameters: {'track_id': trackId});

  // ── Streak ───────────────────────────────────────────────────────────────────

  Future<void> logStreakMilestone({required int streak}) =>
      _fa.logEvent(name: 'streak_milestone', parameters: {'streak': streak});

  // ── Conversation (free mode, no scenario) ────────────────────────────────────

  Future<void> logConversationStarted() =>
      _fa.logEvent(name: 'conversation_started');

  Future<void> logConversationEnded({required int durationSeconds}) =>
      _fa.logEvent(name: 'conversation_ended', parameters: {
        'duration_seconds': durationSeconds,
      });

  // ── Auth ─────────────────────────────────────────────────────────────────────

  Future<void> logSignUp({required String method}) =>
      _fa.logSignUp(signUpMethod: method);

  Future<void> logLogin({required String method}) =>
      _fa.logLogin(loginMethod: method);

  Future<void> setUserId(String? uid) => _fa.setUserId(id: uid);
}
