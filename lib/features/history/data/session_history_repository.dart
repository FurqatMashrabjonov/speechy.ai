import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/features/history/data/session_history_remote_repository.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';

class SessionHistoryRepository {
  static const _key = 'session_history';
  final SharedPreferences _prefs;
  final SessionHistoryRemoteRepository _remote;

  SessionHistoryRepository(this._prefs, this._remote);

  List<SessionHistoryEntry> _loadAll() {
    final json = _prefs.getString(_key);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => SessionHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SessionHistoryRepository: failed to load: $e');
      return [];
    }
  }

  Future<void> _saveAll(List<SessionHistoryEntry> entries) async {
    final json = jsonEncode(entries.map((e) => e.toMap()).toList());
    await _prefs.setString(_key, json);
  }

  Future<void> saveSession(SessionHistoryEntry entry) async {
    final entries = _loadAll();
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      entries[idx] = entry;
    } else {
      entries.add(entry);
    }
    await _saveAll(entries);
    // Dual-write to Firestore (background — local is source of truth)
    _remote.save(entry).catchError((_) {});
  }

  Future<String> savePendingSession({
    required String scenarioId,
    required String scenarioTitle,
    required String category,
    required String transcript,
    required int durationSeconds,
    required String scenarioPrompt,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final entry = SessionHistoryEntry(
      id: id,
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      category: category,
      transcript: transcript,
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
      feedbackStatus: 'pending',
      scenarioPrompt: scenarioPrompt,
    );
    await saveSession(entry);
    return id;
  }

  Future<void> updateSessionWithFeedback({
    required String sessionId,
    required int overallScore,
    required int clarity,
    required int confidence,
    required int engagement,
    required int relevance,
    required String summary,
    required List<String> strengths,
    required List<String> improvements,
    required int xpEarned,
  }) async {
    final entries = _loadAll();
    final idx = entries.indexWhere((e) => e.id == sessionId);
    if (idx >= 0) {
      entries[idx] = entries[idx].copyWith(
        overallScore: overallScore,
        clarity: clarity,
        confidence: confidence,
        engagement: engagement,
        relevance: relevance,
        summary: summary,
        strengths: strengths,
        improvements: improvements,
        xpEarned: xpEarned,
        feedbackStatus: 'completed',
        feedbackGeneratedBy: 'client',
      );
      await _saveAll(entries);
    } else {
      debugPrint('SessionHistoryRepository: session $sessionId not found for feedback update');
    }
  }

  Future<List<SessionHistoryEntry>> getSessions({int limit = 50}) async {
    final entries = _loadAll();
    // Sort by createdAt descending (newest first)
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries.take(limit).toList();
  }

  Future<SessionHistoryEntry?> getSession(String id) async {
    final entries = _loadAll();
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Restore sessions from Firestore into local cache.
  /// Used on first login / new device — merges without overwriting local transcripts.
  Future<List<SessionHistoryEntry>> syncFromCloud() async {
    try {
      final remote = await _remote
          .loadAll()
          .timeout(const Duration(seconds: 8));
      if (remote.isEmpty) return getSessions();
      final local = _loadAll();
      final merged = SessionHistoryRemoteRepository.merge(local, remote);
      await _saveAll(merged);
      return merged..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('SessionHistoryRepository: cloud sync failed: $e');
      return getSessions();
    }
  }
}

final sessionHistoryRepositoryProvider = Provider<SessionHistoryRepository>(
  (ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    final remote = ref.read(sessionHistoryRemoteRepositoryProvider);
    return SessionHistoryRepository(prefs, remote);
  },
);
