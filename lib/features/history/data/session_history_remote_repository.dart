import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/features/history/domain/session_history_entity.dart';

class SessionHistoryRemoteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SessionHistoryRemoteRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _sessionsCol {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('sessions');
  }

  /// Save session to Firestore — strips transcript for privacy/size.
  Future<void> save(SessionHistoryEntry entry) async {
    final col = _sessionsCol;
    if (col == null) return;
    try {
      await col.doc(entry.id).set(_toRemoteMap(entry), SetOptions(merge: true));
    } catch (e) {
      debugPrint('SessionHistoryRemote: save failed: $e');
    }
  }

  Future<List<SessionHistoryEntry>> loadAll({int limit = 50}) async {
    final col = _sessionsCol;
    if (col == null) return [];
    try {
      final snap = await col
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => _fromRemoteMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('SessionHistoryRemote: loadAll failed: $e');
      return [];
    }
  }

  /// Merge remote entries into local list, deduping by id.
  /// Local entries are preferred (they may have transcripts).
  static List<SessionHistoryEntry> merge(
    List<SessionHistoryEntry> local,
    List<SessionHistoryEntry> remote,
  ) {
    final map = <String, SessionHistoryEntry>{};
    for (final r in remote) {
      map[r.id] = r;
    }
    // Local overrides remote (preserves transcript)
    for (final l in local) {
      map[l.id] = l;
    }
    final merged = map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  static Map<String, dynamic> _toRemoteMap(SessionHistoryEntry e) => {
        'scenarioId': e.scenarioId,
        'scenarioTitle': e.scenarioTitle,
        'category': e.category,
        'overallScore': e.overallScore,
        'clarity': e.clarity,
        'confidence': e.confidence,
        'engagement': e.engagement,
        'relevance': e.relevance,
        'summary': e.summary,
        'strengths': e.strengths,
        'improvements': e.improvements,
        'durationSeconds': e.durationSeconds,
        'createdAt': e.createdAt.toIso8601String(),
        'feedbackStatus': e.feedbackStatus,
        if (e.feedbackGeneratedBy != null)
          'feedbackGeneratedBy': e.feedbackGeneratedBy,
        // transcript intentionally excluded — privacy + size
      };

  static SessionHistoryEntry _fromRemoteMap(
    String id,
    Map<String, dynamic> d,
  ) =>
      SessionHistoryEntry(
        id: id,
        scenarioId: d['scenarioId'] as String? ?? '',
        scenarioTitle: d['scenarioTitle'] as String? ?? '',
        category: d['category'] as String? ?? '',
        overallScore: (d['overallScore'] as num?)?.toInt(),
        clarity: (d['clarity'] as num?)?.toInt(),
        confidence: (d['confidence'] as num?)?.toInt(),
        engagement: (d['engagement'] as num?)?.toInt(),
        relevance: (d['relevance'] as num?)?.toInt(),
        summary: d['summary'] as String?,
        strengths: d['strengths'] != null
            ? List<String>.from(d['strengths'] as List)
            : null,
        improvements: d['improvements'] != null
            ? List<String>.from(d['improvements'] as List)
            : null,
        transcript: '', // not stored remotely
        durationSeconds: (d['durationSeconds'] as num?)?.toInt() ?? 0,
        createdAt: d['createdAt'] != null
            ? DateTime.tryParse(d['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        feedbackStatus: d['feedbackStatus'] as String? ?? 'completed',
        feedbackGeneratedBy: d['feedbackGeneratedBy'] as String?,
      );
}

final sessionHistoryRemoteRepositoryProvider =
    Provider<SessionHistoryRemoteRepository>(
  (_) => SessionHistoryRemoteRepository(),
);
