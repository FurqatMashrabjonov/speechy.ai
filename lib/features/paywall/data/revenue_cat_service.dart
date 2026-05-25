import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _apiKey = 'test_GJMzlpFhOxqaWpNXeaHBwWLsIcP';

  bool _initialized = false;

  Future<void> init({String? appUserId}) async {
    if (_initialized) return;

    await Purchases.setLogLevel(LogLevel.debug);

    final configuration = PurchasesConfiguration(_apiKey);
    if (appUserId != null) {
      configuration.appUserID = appUserId;
    }

    await Purchases.configure(configuration);
    _initialized = true;
    log('[RevenueCat] SDK initialized');
  }

  Future<bool> checkProStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasAny = customerInfo.entitlements.active.isNotEmpty;
      log('[RevenueCat] Has active entitlement: $hasAny');
      return hasAny;
    } catch (e) {
      log('[RevenueCat] Error checking status: $e');
      return false;
    }
  }

  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      log('[RevenueCat] Offerings loaded: ${offerings.current?.identifier}');
      return offerings;
    } catch (e) {
      log('[RevenueCat] Error fetching offerings: $e');
      return null;
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      // Check the specific tier entitlement (identifier = 'basic'/'pro'/'ultra')
      final entitlement = result.customerInfo.entitlements.all[package.identifier];
      return entitlement?.isActive ?? result.customerInfo.entitlements.active.isNotEmpty;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        log('[RevenueCat] Purchase cancelled by user');
        throw PurchaseCancelledException();
      }
      log('[RevenueCat] Purchase error: $errorCode');
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final hasAny = customerInfo.entitlements.active.isNotEmpty;
      log('[RevenueCat] Restore result - has active: $hasAny');
      return hasAny;
    } catch (e) {
      log('[RevenueCat] Restore error: $e');
      return false;
    }
  }

  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// No-op: use Flutter /paywall route instead of RevenueCat native UI.
  Future<bool> presentPaywall() async => false;

  /// No-op: use Flutter /paywall route instead of RevenueCat native UI.
  Future<bool> presentPaywallIfNeeded() async => false;

  /// No-op: Customer Center not available without purchases_ui_flutter.
  Future<void> presentCustomerCenter() async {}

  Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
      log('[RevenueCat] Logged in user: $userId');
    } catch (e) {
      log('[RevenueCat] Login error: $e');
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      log('[RevenueCat] Logged out');
    } catch (e) {
      log('[RevenueCat] Logout error: $e');
    }
  }
}

/// Thrown when the user cancels a purchase.
class PurchaseCancelledException implements Exception {}
