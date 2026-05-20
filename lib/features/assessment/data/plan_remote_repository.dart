import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/learning_plan_entity.dart';

class PlanRemoteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PlanRemoteRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>? get _planDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('data')
        .doc('plan');
  }

  Future<void> save(LearningPlan plan) async {
    final doc = _planDoc;
    if (doc == null) return;
    try {
      await doc.set({
        ...plan.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('PlanRemoteRepository.save failed: $e');
    }
  }

  Future<LearningPlan?> load() async {
    final doc = _planDoc;
    if (doc == null) return null;
    try {
      final snapshot = await doc.get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = Map<String, dynamic>.from(snapshot.data()!);
      data.remove('updatedAt');
      return LearningPlan.fromMap(data);
    } catch (e) {
      debugPrint('PlanRemoteRepository.load failed: $e');
      return null;
    }
  }

  /// Remote wins if local has no plan. Local wins if both exist (more up-to-date).
  static LearningPlan? merge(LearningPlan? local, LearningPlan? remote) {
    if (local == null) return remote;
    if (remote == null) return local;
    // Pick whichever has more completed steps (resuming from another device)
    return local.completedCount >= remote.completedCount ? local : remote;
  }
}

final planRemoteRepositoryProvider = Provider<PlanRemoteRepository>(
  (ref) => PlanRemoteRepository(),
);
