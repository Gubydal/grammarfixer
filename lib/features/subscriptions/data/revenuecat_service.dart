import 'package:purchases_flutter/purchases_flutter.dart';

/// Thin wrapper around RevenueCat's current API.
///
/// The SDK key is a public mobile key; RevenueCat dashboard -> API Keys.
class RevenuecatService {
  RevenuecatService._();

  static Future<void> configureRevenueCat(String apiKey) async {
    if (apiKey.isEmpty) return;
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  static Future<Offerings?> fetchOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  static Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      return result.customerInfo;
    } catch (_) {
      return null;
    }
  }

  static Future<CustomerInfo?> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isProUser() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('pro');
    } catch (_) {
      return false;
    }
  }

  static void addCustomerInfoUpdateListener(
    CustomerInfoUpdateListener listener,
  ) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  static void removeCustomerInfoUpdateListener(
    CustomerInfoUpdateListener listener,
  ) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }
}
