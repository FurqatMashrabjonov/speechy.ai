import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class RevenueCatService {
  static const _apiKey = 'test_wpYJJTxBrHOoUrDwlCMpNiCDbRJ';
  static const proEntitlementId = 'pro';

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
      final isPro =
          customerInfo.entitlements.all[proEntitlementId]?.isActive ?? false;
      log('[RevenueCat] Pro status: $isPro');
      return isPro;
    } catch (e) {
      log('[RevenueCat] Error checking pro status: $e');
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
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all[proEntitlementId]?.isActive ?? false;
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
      final isPro =
          customerInfo.entitlements.all[proEntitlementId]?.isActive ?? false;
      log('[RevenueCat] Restore result - isPro: $isPro');
      return isPro;
    } catch (e) {
      log('[RevenueCat] Restore error: $e');
      return false;
    }
  }

  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Present RevenueCat's remote paywall UI.
  /// Returns true if the user made a purchase.
  Future<bool> presentPaywall() async {
    final result = await RevenueCatUI.presentPaywall();
    log('[RevenueCat] Paywall result: $result');
    return result == PaywallResult.purchased;
  }

  /// Present paywall only if the user doesn't have the "pro" entitlement.
  /// Returns true if the user made a purchase.
  Future<bool> presentPaywallIfNeeded() async {
    final result =
        await RevenueCatUI.presentPaywallIfNeeded(proEntitlementId);
    log('[RevenueCat] PaywallIfNeeded result: $result');
    return result == PaywallResult.purchased;
  }

  /// Open RevenueCat Customer Center for subscription management.
  Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

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
