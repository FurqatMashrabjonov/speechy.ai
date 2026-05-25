import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/core/errors/error_reporter.dart';
import 'package:speech_coach/features/feedback/domain/feedback_entity.dart';
import 'package:speech_coach/features/history/data/session_history_repository.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';

enum SessionHistoryStatus { idle, loading, loaded, error }

class SessionHistoryState {
  final SessionHistoryStatus status;
  final List<SessionHistoryEntry> sessions;
  final String? error;

  const SessionHistoryState({
    this.status = SessionHistoryStatus.idle,
    this.sessions = const [],
    this.error,
  });

  SessionHistoryState copyWith({
    SessionHistoryStatus? status,
    List<SessionHistoryEntry>? sessions,
    String? error,
  }) {
    return SessionHistoryState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      error: error,
    );
  }
}

class SessionHistoryNotifier extends StateNotifier<SessionHistoryState> {
  final SessionHistoryRepository _repository;

  SessionHistoryNotifier(this._repository)
      : super(const SessionHistoryState());

  Future<void> loadSessions() async {
    state = state.copyWith(status: SessionHistoryStatus.loading);
    try {
      // Show local data immediately (fast)
      final local = await _repository.getSessions();
      state = state.copyWith(
        status: SessionHistoryStatus.loaded,
        sessions: local,
      );
      // Then merge with Firestore in background (restores cross-device history)
      _syncFromCloud();
    } catch (e) {
      state = state.copyWith(
        status: SessionHistoryStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final merged = await _repository.syncFromCloud();
      if (mounted) {
        state = state.copyWith(
          status: SessionHistoryStatus.loaded,
          sessions: merged,
        );
      }
    } catch (e, st) {
      reportError(e, st, context: 'session_history_cloud_sync');
    }
  }

}

final sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, SessionHistoryState>((ref) {
  final repository = ref.read(sessionHistoryRepositoryProvider);
  return SessionHistoryNotifier(repository);
});

class SessionSaver {
  final SessionHistoryRepository _repository;

  SessionSaver(this._repository);

  Future<void> save({
    required String scenarioId,
    required String scenarioTitle,
    required String category,
    required ConversationFeedback feedback,
    required String transcript,
  }) async {
    final entry = SessionHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      category: category,
      overallScore: feedback.overallScore,
      clarity: feedback.clarity,
      confidence: feedback.confidence,
      engagement: feedback.engagement,
      relevance: feedback.relevance,
      summary: feedback.summary,
      strengths: feedback.strengths,
      improvements: feedback.improvements,
      transcript: transcript,
      durationSeconds: feedback.durationSeconds,
      createdAt: DateTime.now(),
    );

    await _repository.saveSession(entry);
  }
}

final saveSessionProvider = Provider<SessionSaver>((ref) {
  final repository = ref.read(sessionHistoryRepositoryProvider);
  return SessionSaver(repository);
});

class PendingSessionSaver {
  final SessionHistoryRepository _repository;

  PendingSessionSaver(this._repository);

  Future<String> savePending({
    required String scenarioId,
    required String scenarioTitle,
    required String category,
    required String transcript,
    required int durationSeconds,
    required String scenarioPrompt,
  }) {
    return _repository.savePendingSession(
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      category: category,
      transcript: transcript,
      durationSeconds: durationSeconds,
      scenarioPrompt: scenarioPrompt,
    );
  }

  Future<void> completeFeedback({
    required String sessionId,
    required ConversationFeedback feedback,
  }) {
    return _repository.updateSessionWithFeedback(
      sessionId: sessionId,
      overallScore: feedback.overallScore,
      clarity: feedback.clarity,
      confidence: feedback.confidence,
      engagement: feedback.engagement,
      relevance: feedback.relevance,
      summary: feedback.summary,
      strengths: feedback.strengths,
      improvements: feedback.improvements,
    );
  }
}

final pendingSessionSaverProvider = Provider<PendingSessionSaver>((ref) {
  return PendingSessionSaver(ref.read(sessionHistoryRepositoryProvider));
});
