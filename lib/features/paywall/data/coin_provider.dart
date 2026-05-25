import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_coach/features/paywall/data/coins_remote_repository.dart';

class CoinState {
  final int balance;
  final bool isLoading;

  const CoinState({this.balance = 0, this.isLoading = true});

  bool get canStartSession => balance >= 5;

  CoinState copyWith({int? balance, bool? isLoading}) => CoinState(
        balance: balance ?? this.balance,
        isLoading: isLoading ?? this.isLoading,
      );
}

class CoinNotifier extends StateNotifier<CoinState> {
  final CoinsRemoteRepository _repo;

  static const int _signupBonus = 5;

  CoinNotifier(this._repo) : super(const CoinState()) {
    _init();
  }

  Future<void> _init() async {
    await _repo.initializeIfNew(_signupBonus);
    final balance = await _repo.fetchBalance();
    if (mounted) {
      state = CoinState(balance: balance ?? _signupBonus, isLoading: false);
    }
  }

  // Call on login to pull latest balance from Firestore.
  Future<void> refresh() async {
    final balance = await _repo.fetchBalance();
    if (balance != null && mounted) {
      state = state.copyWith(balance: balance, isLoading: false);
    }
  }

  // Optimistic local -1 + async Firestore write. Called every 60s during session.
  void deductCoin() {
    if (state.balance <= 0) return;
    state = state.copyWith(balance: state.balance - 1);
    unawaited(_repo.decrementCoin());
  }

  Future<void> addCoins(int amount) async {
    state = state.copyWith(balance: state.balance + amount);
    await _repo.addCoins(amount);
    // Re-sync to catch any server-side discrepancy
    await refresh();
  }
}

final coinProvider = StateNotifierProvider<CoinNotifier, CoinState>((ref) {
  final repo = ref.read(coinsRemoteRepositoryProvider);
  return CoinNotifier(repo);
});
