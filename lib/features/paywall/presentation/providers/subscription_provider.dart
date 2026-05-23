import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:speech_coach/features/assessment/data/assessment_data.dart';
import 'package:speech_coach/features/paywall/data/revenue_cat_service.dart';
import 'package:speech_coach/features/paywall/data/usage_service.dart';
import 'package:speech_coach/features/paywall/domain/track_tier.dart';

class SubscriptionState {
  final bool isPurchasing;
  final bool isRestoring;
  final List<Package> availablePackages;
  final Map<String, TrackTier> purchasedTiers; // trackId → tier
  final String? error;

  const SubscriptionState({
    this.isPurchasing = false,
    this.isRestoring = false,
    this.availablePackages = const [],
    this.purchasedTiers = const {},
    this.error,
  });

  // Legacy — kept so existing widgets that read isPro don't break immediately.
  // Will be removed once all screens are migrated.
  bool get isPro => purchasedTiers.isNotEmpty;

  /// Highest tier the user has purchased across all tracks.
  TrackTier? get highestTier {
    TrackTier? best;
    for (final tier in purchasedTiers.values) {
      if (best == null || tier.sessionCount > best.sessionCount) best = tier;
    }
    return best;
  }

  TrackTier? tierForTrack(String trackId) => purchasedTiers[trackId];

  bool isTrackUnlocked(String trackId) => purchasedTiers.containsKey(trackId);

  Package? packageForTier(TrackTier tier) {
    for (final pkg in availablePackages) {
      if (pkg.identifier == tier.revenueCatIdentifier) return pkg;
    }
    return null;
  }

  SubscriptionState copyWith({
    bool? isPurchasing,
    bool? isRestoring,
    List<Package>? availablePackages,
    Map<String, TrackTier>? purchasedTiers,
    String? error,
  }) {
    return SubscriptionState(
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      availablePackages: availablePackages ?? this.availablePackages,
      purchasedTiers: purchasedTiers ?? this.purchasedTiers,
      error: error,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final RevenueCatService _service;
  final UsageService _usageService;

  SubscriptionNotifier(this._service, this._usageService)
      : super(const SubscriptionState()) {
    _init();
  }

  Future<void> _init() async {
    _loadStoredTiers();
    await loadOfferings();
  }

  void _loadStoredTiers() {
    final tiers = <String, TrackTier>{};
    for (final meta in allRoadmapMetas) {
      final tier = _usageService.getTrackTier(meta.id);
      if (tier != null) tiers[meta.id] = tier;
    }
    state = state.copyWith(purchasedTiers: tiers);
  }

  Future<void> loadOfferings() async {
    final offerings = await _service.getOfferings();
    final packages = offerings?.current?.availablePackages ?? [];
    state = state.copyWith(availablePackages: packages);
  }

  /// Purchase a tier for a specific track.
  Future<bool> purchaseTier({
    required String trackId,
    required TrackTier tier,
  }) async {
    state = state.copyWith(isPurchasing: true, error: null);

    final package = state.packageForTier(tier);

    if (package == null) {
      // Dev fallback: simulate purchase
      await Future.delayed(const Duration(milliseconds: 800));
      await _applyTier(trackId, tier);
      state = state.copyWith(isPurchasing: false);
      return true;
    }

    try {
      final success = await _service.purchasePackage(package);
      if (success) await _applyTier(trackId, tier);
      state = state.copyWith(isPurchasing: false);
      return success;
    } on PurchaseCancelledException {
      state = state.copyWith(isPurchasing: false);
      return false;
    } on PlatformException catch (_) {
      state = state.copyWith(
        isPurchasing: false,
        error: 'Purchase failed. Please try again.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isPurchasing: false,
        error: 'Purchase failed. Please try again.',
      );
      return false;
    }
  }

  Future<void> restore({required String trackId}) async {
    state = state.copyWith(isRestoring: true, error: null);
    try {
      final isPro = await _service.restorePurchases();
      if (!isPro) {
        state = state.copyWith(
          isRestoring: false,
          error: 'No previous purchases found.',
        );
      } else {
        await _applyTier(trackId, TrackTier.ultra);
        state = state.copyWith(isRestoring: false);
      }
    } catch (_) {
      state = state.copyWith(
        isRestoring: false,
        error: 'Restore failed. Please try again.',
      );
    }
  }

  Future<void> _applyTier(String trackId, TrackTier tier) async {
    await _usageService.setTrackTier(trackId, tier);
    final updated = Map<String, TrackTier>.from(state.purchasedTiers);
    // Only upgrade, never downgrade
    final current = updated[trackId];
    if (current == null || tier.sessionCount > current.sessionCount) {
      updated[trackId] = tier;
    }
    state = state.copyWith(purchasedTiers: updated);
  }
}

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final service = ref.read(revenueCatServiceProvider);
  final usageService = ref.read(usageServiceProvider);
  return SubscriptionNotifier(service, usageService);
});
