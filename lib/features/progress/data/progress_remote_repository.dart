import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/features/progress/domain/progress_entity.dart';

class ProgressRemoteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProgressRemoteRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>? get _progressDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('data').doc('progress');
  }

  Future<void> save(UserProgress progress) async {
    final doc = _progressDoc;
    if (doc == null) return;

    try {
      // Store last 50 session records for analytics restore on new device
      final recentHistory = progress.sessionHistory.length > 50
          ? progress.sessionHistory.sublist(progress.sessionHistory.length - 50)
          : progress.sessionHistory;

      await doc.set({
        'streak': progress.streak,
        'longestStreak': progress.longestStreak,
        'totalSessions': progress.totalSessions,
        'totalMinutes': progress.totalMinutes,
        'lastSessionDate': progress.lastSessionDate?.toIso8601String(),
        'badges': progress.badges,
        'sessionHistory': recentHistory.map((s) => s.toMap()).toList(),
        'streakFreezes': progress.streakFreezes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save progress to Firestore: $e');
    }
  }

  Future<UserProgress?> load() async {
    final doc = _progressDoc;
    if (doc == null) return null;

    try {
      final snapshot = await doc.get();
      if (!snapshot.exists || snapshot.data() == null) return null;

      final data = snapshot.data()!;
      return UserProgress(
        streak: (data['streak'] as num?)?.toInt() ?? 0,
        longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
        totalSessions: (data['totalSessions'] as num?)?.toInt() ?? 0,
        totalMinutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
        lastSessionDate: data['lastSessionDate'] != null
            ? DateTime.tryParse(data['lastSessionDate'] as String)
            : null,
        badges: List<String>.from(data['badges'] as List? ?? []),
        sessionHistory: (data['sessionHistory'] as List? ?? [])
            .map((s) => SessionRecord.fromMap(s as Map<String, dynamic>))
            .toList(),
        streakFreezes: (data['streakFreezes'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('Failed to load progress from Firestore: $e');
      return null;
    }
  }

  /// Merge local and remote progress, taking the higher/better values.
  static UserProgress merge(UserProgress local, UserProgress remote) {
    final mergedBadges = {...local.badges, ...remote.badges}.toList();

    DateTime? mergedLastSession;
    if (local.lastSessionDate != null && remote.lastSessionDate != null) {
      mergedLastSession = local.lastSessionDate!.isAfter(remote.lastSessionDate!)
          ? local.lastSessionDate
          : remote.lastSessionDate;
    } else {
      mergedLastSession = local.lastSessionDate ?? remote.lastSessionDate;
    }

    // Union sessionHistory by date — dedupe by scenarioId+date combo
    final allRecords = {...local.sessionHistory, ...remote.sessionHistory}.toList();
    final seen = <String>{};
    final mergedHistory = <SessionRecord>[];
    for (final r in allRecords) {
      final key = '${r.scenarioId}_${r.date.toIso8601String()}';
      if (seen.add(key)) mergedHistory.add(r);
    }
    mergedHistory.sort((a, b) => a.date.compareTo(b.date));

    return local.copyWith(
      streak: local.streak > remote.streak ? local.streak : remote.streak,
      longestStreak: local.longestStreak > remote.longestStreak
          ? local.longestStreak
          : remote.longestStreak,
      totalSessions: local.totalSessions > remote.totalSessions
          ? local.totalSessions
          : remote.totalSessions,
      totalMinutes: local.totalMinutes > remote.totalMinutes
          ? local.totalMinutes
          : remote.totalMinutes,
      lastSessionDate: mergedLastSession,
      badges: mergedBadges,
      sessionHistory: mergedHistory,
      streakFreezes: local.streakFreezes > remote.streakFreezes
          ? local.streakFreezes
          : remote.streakFreezes,
    );
  }
}

final progressRemoteRepositoryProvider = Provider<ProgressRemoteRepository>(
  (ref) => ProgressRemoteRepository(),
);
