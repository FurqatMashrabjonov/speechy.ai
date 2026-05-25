import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/features/paywall/data/limits_remote_repository.dart';
import 'package:speech_coach/features/paywall/domain/track_tier.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';

class UsageService {
  static const _keyTotalFree = 'total_free_sessions_used';
  static const int freeTotalSessions = 3;

  final SharedPreferences _prefs;
  final LimitsRemoteRepository _remote;

  UsageService(this._prefs, this._remote);

  // ── Free trial ────────────────────────────────────────────────────────────

  int get totalFreeSessionsUsed => _prefs.getInt(_keyTotalFree) ?? 0;
  bool get hasFreeSessionsLeft => totalFreeSessionsUsed < freeTotalSessions;
  int get remainingFreeSessions =>
      (freeTotalSessions - totalFreeSessionsUsed).clamp(0, freeTotalSessions);

  Future<void> recordFreeSession() async {
    await _prefs.setInt(_keyTotalFree, totalFreeSessionsUsed + 1);
    unawaited(_remote.incrementFreeSession());
  }

  // ── Remote sync — call on every login ────────────────────────────────────

  Future<void> syncFromRemote() async {
    final remote = await _remote.fetch();
    if (remote == null) return;

    // Take max(local, remote) — handles offline sessions on this device
    if (remote.freeSessionsUsed > totalFreeSessionsUsed) {
      await _prefs.setInt(_keyTotalFree, remote.freeSessionsUsed);
      debugPrint(
        'LimitsSync: free sessions updated $totalFreeSessionsUsed → ${remote.freeSessionsUsed}',
      );
    }

    for (final entry in remote.stepAttempts.entries) {
      // key format: "trackId_stepOrder" — stepOrder is always a plain int suffix
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
    final current = getTrackTier(trackId);
    // Only upgrade, never downgrade
    if (current != null && current.sessionCount >= tier.sessionCount) return;
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

  bool canAttemptStep(String trackId, int stepOrder) {
    final tier = getTrackTier(trackId);
    // Free users get exactly 1 attempt per step — no retries
    final maxAttempts = tier?.maxAttempts ?? 1;
    return getAttemptCount(trackId, stepOrder) < maxAttempts;
  }

  // ── Session gate ──────────────────────────────────────────────────────────

  /// Returns true if user can start a session for this step.
  /// [trackId] and [stepOrder] are optional — if omitted, falls back to free trial check.
  bool canStartSession({String? trackId, int? stepOrder}) {
    if (trackId == null || stepOrder == null) {
      return hasFreeSessionsLeft;
    }
    final tier = getTrackTier(trackId);
    if (tier != null) {
      return stepOrder < tier.sessionCount && canAttemptStep(trackId, stepOrder);
    }
    // Free: global sessions left AND this specific step not yet attempted
    return hasFreeSessionsLeft && canAttemptStep(trackId, stepOrder);
  }

  Future<void> recordSession({String? trackId, int? stepOrder}) async {
    if (trackId != null && stepOrder != null) {
      // Always track per-step attempts (free and paid alike)
      await incrementAttempt(trackId, stepOrder);
      final tier = getTrackTier(trackId);
      if (tier == null) {
        // Also consume a global free session
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
