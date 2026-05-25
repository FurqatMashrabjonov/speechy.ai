import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LimitsData {
  final int freeSessionsUsed;
  final Map<String, int> stepAttempts; // key: "trackId_stepOrder"

  const LimitsData({
    this.freeSessionsUsed = 0,
    this.stepAttempts = const {},
  });
}

class LimitsRemoteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LimitsRemoteRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('data')
        .doc('limits');
  }

  Future<LimitsData?> fetch() async {
    final doc = _doc;
    if (doc == null) return null;
    try {
      final snap = await doc.get().timeout(const Duration(seconds: 5));
      if (!snap.exists) return const LimitsData();
      final d = snap.data()!;
      final rawAttempts = d['stepAttempts'] as Map<String, dynamic>? ?? {};
      return LimitsData(
        freeSessionsUsed: (d['freeSessionsUsed'] as num?)?.toInt() ?? 0,
        stepAttempts: rawAttempts.map((k, v) => MapEntry(k, (v as num).toInt())),
      );
    } catch (e) {
      debugPrint('LimitsRemote: fetch failed: $e');
      return null;
    }
  }

  Future<void> incrementFreeSession() async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.set(
        {'freeSessionsUsed': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('LimitsRemote: incrementFreeSession failed: $e');
    }
  }

  Future<void> incrementStepAttempt(String trackId, int stepOrder) async {
    final doc = _doc;
    if (doc == null) return;
    final key = '${trackId}_$stepOrder';
    try {
      await doc.set(
        {
          'stepAttempts': {key: FieldValue.increment(1)},
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('LimitsRemote: incrementStepAttempt failed: $e');
    }
  }
}

final limitsRemoteRepositoryProvider = Provider<LimitsRemoteRepository>(
  (_) => LimitsRemoteRepository(),
);
