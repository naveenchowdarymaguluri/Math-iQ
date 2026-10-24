import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Entitlement identifier configured in the RevenueCat dashboard.
const _kEntitlement = 'Math IQ Pro';

/// RevenueCat product identifiers that map to your configured offerings.
/// These must match the identifiers in your RevenueCat dashboard.
class RCProducts {
  RCProducts._();
  static const monthly  = 'monthly';
  static const yearly   = 'yearly';
  static const lifetime = 'lifetime';
}

/// Thin ChangeNotifier wrapper around the RevenueCat SDK.
///
/// Usage:
///   await SubscriptionService.instance.initialize();   // in main()
///   SubscriptionService.instance.isPro                 // true when entitled
class SubscriptionService extends ChangeNotifier {
  static final instance = SubscriptionService._();
  SubscriptionService._();

  // ⚠️ Subscriptions are DISABLED for this release.
  // RevenueCat is not configured — `isPro` is always false and the app runs in
  // free/ad-supported mode. To re-enable: set [_subscriptionsEnabled] to true
  // and replace [_rcApiKey] with your PRODUCTION key from the RevenueCat
  // dashboard (platform-specific keys recommended).
  static const bool _subscriptionsEnabled = false;
  static const _rcApiKey = 'REPLACE_WITH_PRODUCTION_KEY';

  CustomerInfo? _customerInfo;
  bool _isLoading = false;
  String? _lastError;

  // ── Public state ──────────────────────────────────────────────────────────

  /// Whether subscriptions/paywall are available in this build.
  bool get subscriptionsEnabled => _subscriptionsEnabled;

  /// True when the user holds an active "Math IQ Pro" entitlement.
  bool get isPro =>
      _customerInfo?.entitlements.active.containsKey(_kEntitlement) ?? false;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  CustomerInfo? get customerInfo => _customerInfo;

  /// The active entitlement object, or null if not subscribed.
  EntitlementInfo? get proEntitlement =>
      _customerInfo?.entitlements.active[_kEntitlement];

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Subscriptions disabled — skip RevenueCat configuration entirely so no
    // test key ships and the app runs purely in free/ad-supported mode.
    if (!_subscriptionsEnabled) {
      if (kDebugMode) {
        debugPrint('[Subscription] disabled — running in free mode');
      }
      return;
    }

    if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);

    await Purchases.configure(PurchasesConfiguration(_rcApiKey));

    // Stream real-time entitlement changes (e.g. subscription renewed/expired).
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) debugPrint('[Subscription] init error: $e');
    }
    notifyListeners();
  }

  // ── Customer info ─────────────────────────────────────────────────────────

  /// Force-refreshes CustomerInfo from RevenueCat servers.
  Future<void> refresh() async {
    if (!_subscriptionsEnabled) return;
    _setLoading(true);
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) debugPrint('[Subscription] refresh error: $e');
    }
    _setLoading(false);
  }

  // ── Purchases ─────────────────────────────────────────────────────────────

  /// Restores previous purchases and returns true if the user is now Pro.
  Future<bool> restorePurchases() async {
    if (!_subscriptionsEnabled) return false;
    _setLoading(true);
    try {
      _customerInfo = await Purchases.restorePurchases();
      _lastError = null;
      notifyListeners();
      return isPro;
    } catch (e) {
      _lastError = e.toString();
      if (kDebugMode) debugPrint('[Subscription] restore error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Offerings ─────────────────────────────────────────────────────────────

  /// Fetches the current RevenueCat offerings.
  Future<Offerings?> getOfferings() async {
    if (!_subscriptionsEnabled) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      if (kDebugMode) debugPrint('[Subscription] getOfferings error: $e');
      return null;
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _customerInfo = info;
    _lastError = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
