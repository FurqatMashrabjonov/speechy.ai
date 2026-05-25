import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/features/paywall/data/limits_remote_repository.dart';
import 'package:speech_coach/features/paywall/domain/track_tier.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';

class UsageService {
  static const _keyTotalFree = 'total_free_sessions_used';
  // Free-form conversations (no track) get 3 global free sessions.
  static const int freeTotalSessions = 3;

  final SharedPreferences _prefs;
  final LimitsRemoteRepository _remote;

  UsageService(this._prefs, this._remote);

  // ── Free trial (free-form conversations) ─────────────────────────────────

  int get totalFreeSessionsUsed => _prefs.getInt(_keyTotalFree) ?? 0;
  bool get hasFreeSessionsLeft => totalFreeSessionsUsed < freeTotalSessions;
  int get remainingFreeSessions =>
      (freeTotalSessions - totalFreeSessionsUsed).clamp(0, freeTotalSessions);

  Future<void> recordFreeSession() async {
    await _prefs.setInt(_keyTotalFree, totalFreeSessionsUsed + 1);
    unawaited(_remote.incrementFreeSession());
  }

  // ── Per-track free session — step 0 only, 1 attempt ──────────────────────

  /// Step 0 of each track is always free — but only once, no retry.
  bool isFreeStepAccessible(String trackId) =>
      getAttemptCount(trackId, 0) == 0;

  // ── Remote sync ───────────────────────────────────────────────────────────

  Future<void> syncFromRemote() async {
    final remote = await _remote.fetch();
    if (remote == null) return;

    if (remote.freeSessionsUsed > totalFreeSessionsUsed) {
      await _prefs.setInt(_keyTotalFree, remote.freeSessionsUsed);
      debugPrint(
        'LimitsSync: free sessions updated $totalFreeSessionsUsed → ${remote.freeSessionsUsed}',
      );
    }

    for (final entry in remote.stepAttempts.entries) {
      final lastUnderscore = entry.key.lastIndexOf('_');
      if (lastUnderscore < 0) continue;
      final trackId = entry.key.substring(0, lastUnderscore);
      final stepOrder = int.tryParse(entry.key.substring(lastUnderscore + 1));
      if (stepOrder == null) continue;
      final localCount = getAttemptCount(trackId, stepOrder);
      if (entry.value > localCount) {
        await _prefs.setInt('attempts_${trackId}_$stepOrder', entry.value);
      }
    }
  }

  // ── Track tier ────────────────────────────────────────────────────────────

  TrackTier? getTrackTier(String trackId) =>
      TrackTierX.fromString(_prefs.getString('tier_$trackId'));

  Future<void> setTrackTier(String trackId, TrackTier tier) async {
    // Only upgrade, never downgrade (no-op if already purchased)
    if (getTrackTier(trackId) != null) return;
    await _prefs.setString('tier_$trackId', tier.revenueCatIdentifier);
  }

  // ── Step attempts ─────────────────────────────────────────────────────────

  int getAttemptCount(String trackId, int stepOrder) =>
      _prefs.getInt('attempts_${trackId}_$stepOrder') ?? 0;

  Future<void> incrementAttempt(String trackId, int stepOrder) async {
    await _prefs.setInt(
      'attempts_${trackId}_$stepOrder',
      getAttemptCount(trackId, stepOrder) + 1,
    );
    unawaited(_remote.incrementStepAttempt(trackId, stepOrder));
  }

  /// Paid users: 3 attempts per step.
  /// Free users: 1 attempt on step 0 only; all other steps inaccessible.
  bool canAttemptStep(String trackId, int stepOrder) {
    final tier = getTrackTier(trackId);
    if (tier != null) {
      return getAttemptCount(trackId, stepOrder) < tier.maxAttempts;
    }
    if (stepOrder != 0) return false;
    return isFreeStepAccessible(trackId);
  }

  // ── Session gate ──────────────────────────────────────────────────────────

  bool canStartSession({String? trackId, int? stepOrder}) {
    if (trackId == null || stepOrder == null) {
      return hasFreeSessionsLeft;
    }
    return canAttemptStep(trackId, stepOrder);
  }

  Future<void> recordSession({String? trackId, int? stepOrder}) async {
    if (trackId != null && stepOrder != null) {
      await incrementAttempt(trackId, stepOrder);
      final tier = getTrackTier(trackId);
      if (tier == null) {
        // Free session on step 0 — also consume global free counter
        await recordFreeSession();
      }
      return;
    }
    await recordFreeSession();
  }
}

final usageServiceProvider = Provider<UsageService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  final remote = ref.read(limitsRemoteRepositoryProvider);
  return UsageService(prefs, remote);
});
