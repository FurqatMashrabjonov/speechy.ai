import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/features/feedback/data/feedback_service.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';

class PendingFeedbackService {
  static const _key = 'session_history';

  /// Called once at startup. Finds sessions with feedbackStatus='pending'
  /// created in the last 24 hours and retries analysis for each.
  static Future<void> retryPending(SharedPreferences prefs) async {
    final json = prefs.getString(_key);
    if (json == null) return;

    List<SessionHistoryEntry> entries;
    try {
      final list = jsonDecode(json) as List;
      entries = list
          .map((e) => SessionHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('PendingFeedbackService: failed to parse history: $e');
      return;
    }

    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final pending = entries
        .where((e) => e.isPending && e.createdAt.isAfter(cutoff))
        .toList();

    if (pending.isEmpty) return;
    debugPrint('PendingFeedbackService: found ${pending.length} pending session(s)');

    final service = ConversationFeedbackService();

    for (final session in pending) {
      if (session.transcript.isEmpty) {
        _markFailed(entries, session.id);
        continue;
      }
      try {
        debugPrint('PendingFeedbackService: retrying ${session.id} (${session.scenarioTitle})');
        final feedback = await service.analyzeConversation(
          transcript: session.transcript,
          category: session.category,
          scenarioTitle: session.scenarioTitle,
          scenarioPrompt: session.scenarioPrompt,
          scenarioId: session.scenarioId,
          durationSeconds: session.durationSeconds,
        );

        final idx = entries.indexWhere((e) => e.id == session.id);
        if (idx >= 0) {
          entries[idx] = entries[idx].copyWith(
            overallScore: feedback.overallScore,
            clarity: feedback.clarity,
            confidence: feedback.confidence,
            engagement: feedback.engagement,
            relevance: feedback.relevance,
            summary: feedback.summary,
            strengths: feedback.strengths,
            improvements: feedback.improvements,
            feedbackStatus: 'completed',
            feedbackGeneratedBy: 'client_recovery',
          );
        }
        debugPrint('PendingFeedbackService: recovered ${session.id} — score ${feedback.overallScore}');
      } catch (e) {
        debugPrint('PendingFeedbackService: retry failed for ${session.id}: $e');
        _markFailed(entries, session.id);
      }
    }

    try {
      await prefs.setString(_key, jsonEncode(entries.map((e) => e.toMap()).toList()));
    } catch (e) {
      debugPrint('PendingFeedbackService: failed to persist recovered sessions: $e');
    }
  }

  static void _markFailed(List<SessionHistoryEntry> entries, String id) {
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      entries[idx] = entries[idx].copyWith(feedbackStatus: 'failed');
    }
  }
}
