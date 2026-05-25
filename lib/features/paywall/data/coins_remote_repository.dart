import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoinsRemoteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CoinsRemoteRepository({
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
        .doc('coins');
  }

  Future<int?> fetchBalance() async {
    final doc = _doc;
    if (doc == null) return null;
    try {
      final snap = await doc.get().timeout(const Duration(seconds: 5));
      if (!snap.exists) return null;
      return (snap.data()?['balance'] as num?)?.toInt();
    } catch (e) {
      debugPrint('CoinsRemote: fetchBalance failed: $e');
      return null;
    }
  }

  // Creates the doc with signup bonus only if it doesn't exist yet.
  Future<void> initializeIfNew(int coins) async {
    final doc = _doc;
    if (doc == null) return;
    try {
      final snap = await doc.get().timeout(const Duration(seconds: 5));
      if (!snap.exists) {
        await doc.set({
          'balance': coins,
          'lifetimeEarned': coins,
          'lifetimeSpent': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        debugPrint('CoinsRemote: initialized with $coins coins');
      }
    } catch (e) {
      debugPrint('CoinsRemote: initializeIfNew failed: $e');
    }
  }

  Future<void> addCoins(int amount) async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.set({
        'balance': FieldValue.increment(amount),
        'lifetimeEarned': FieldValue.increment(amount),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CoinsRemote: addCoins failed: $e');
    }
  }

  // Fire-and-forget during session — one call per elapsed minute.
  Future<void> decrementCoin() async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.set({
        'balance': FieldValue.increment(-1),
        'lifetimeSpent': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CoinsRemote: decrementCoin failed: $e');
    }
  }
}

final coinsRemoteRepositoryProvider = Provider<CoinsRemoteRepository>(
  (_) => CoinsRemoteRepository(),
);
