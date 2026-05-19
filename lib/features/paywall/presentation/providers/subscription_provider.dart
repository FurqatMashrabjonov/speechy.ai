import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:speech_coach/features/paywall/data/revenue_cat_service.dart';
import 'package:speech_coach/features/paywall/data/usage_service.dart';

class SubscriptionState {
  final bool isPro;
  final bool isPurchasing;
  final bool isRestoring;
  final List<Package> availablePackages;
  final String? error;

  const SubscriptionState({
    this.isPro = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.availablePackages = const [],
    this.error,
  });

  Package? get monthlyPackage => _findPackage(PackageType.monthly);
  Package? get yearlyPackage => _findPackage(PackageType.annual);
  Package? get lifetimePackage => _findPackage(PackageType.lifetime);

  Package? _findPackage(PackageType type) {
    for (final pkg in availablePackages) {
      if (pkg.packageType == type) return pkg;
    }
    return null;
  }

  SubscriptionState copyWith({
    bool? isPro,
    bool? isPurchasing,
    bool? isRestoring,
    List<Package>? availablePackages,
    String? error,
  }) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      availablePackages: availablePackages ?? this.availablePackages,
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
    final isPro = await _service.checkProStatus();
    await _syncPro(isPro);

    await loadOfferings();

    _service.addCustomerInfoListener((customerInfo) {
      final active =
          customerInfo
              .entitlements
              .all[RevenueCatService.proEntitlementId]
              ?.isActive ??
          false;
      _syncPro(active);
    });
  }

  Future<void> loadOfferings() async {
    final offerings = await _service.getOfferings();
    final packages = offerings?.current?.availablePackages ?? [];
    state = state.copyWith(availablePackages: packages);
  }

  Future<void> purchase(Package? package) async {
    state = state.copyWith(isPurchasing: true, error: null);

    // Simulate purchase for development/fallback when RevenueCat isn't configured
    if (package == null) {
      await Future.delayed(const Duration(seconds: 1));
      await _syncPro(true);
      state = state.copyWith(isPurchasing: false);
      return;
    }

    try {
      final isPro = await _service.purchasePackage(package);
      await _syncPro(isPro);
      state = state.copyWith(isPurchasing: false);
    } on PurchaseCancelledException {
      state = state.copyWith(isPurchasing: false);
    } on PlatformException catch (_) {
      state = state.copyWith(
        isPurchasing: false,
        error: 'Purchase failed. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        isPurchasing: false,
        error: 'Purchase failed. Please try again.',
      );
    }
  }

  Future<void> restore() async {
    state = state.copyWith(isRestoring: true, error: null);
    try {
      final isPro = await _service.restorePurchases();
      await _syncPro(isPro);
      if (!isPro) {
        state = state.copyWith(
          isRestoring: false,
          error: 'No previous purchases found.',
        );
      } else {
        state = state.copyWith(isRestoring: false);
      }
    } catch (_) {
      state = state.copyWith(
        isRestoring: false,
        error: 'Restore failed. Please try again.',
      );
    }
  }

  /// Show RevenueCat's remote paywall. Syncs pro status after.
  Future<void> showPaywall() async {
    final purchased = await _service.presentPaywall();
    if (purchased) {
      final isPro = await _service.checkProStatus();
      await _syncPro(isPro);
    }
  }

  /// Show paywall only if user is not pro. Syncs pro status after.
  Future<void> showPaywallIfNeeded() async {
    final purchased = await _service.presentPaywallIfNeeded();
    if (purchased) {
      final isPro = await _service.checkProStatus();
      await _syncPro(isPro);
    }
  }

  /// Open Customer Center for subscription management.
  Future<void> showCustomerCenter() async {
    await _service.presentCustomerCenter();
    // Re-check status after Customer Center closes (user may have cancelled)
    final isPro = await _service.checkProStatus();
    await _syncPro(isPro);
  }

  Future<void> _syncPro(bool isPro) async {
    await _usageService.setPro(isPro);
    state = state.copyWith(isPro: isPro);
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
