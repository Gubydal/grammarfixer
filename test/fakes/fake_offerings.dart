import 'package:purchases_flutter/purchases_flutter.dart';

/// Builds RevenueCat models for tests without touching the SDK.

Package buildPackage(
  String identifier,
  PackageType type,
  String priceString, {
  String title = 'Pro',
}) {
  return Package(
    identifier,
    type,
    StoreProduct(
      identifier,
      'Test product',
      title,
      9.99,
      priceString,
      'USD',
    ),
    const PresentedOfferingContext('default', null, null),
  );
}

Offering buildOffering({
  Package? monthly,
  Package? annual,
}) {
  return Offering(
    'default',
    'Default offering',
    const {},
    [?monthly, ?annual],
    monthly: monthly,
    annual: annual,
  );
}

Offerings buildOfferings(Offering offering) {
  return Offerings({'default': offering}, current: offering);
}

CustomerInfo buildProCustomer() {
  final pro = EntitlementInfo(
    'pro',
    true,
    true,
    '2026-01-01',
    '2026-01-01',
    'monthly',
    false,
  );
  return CustomerInfo(
    EntitlementInfos({'pro': pro}, {'pro': pro}),
    const {},
    const [],
    const [],
    const [],
    '2026-01-01',
    'orig-user',
    const {},
    '2026-01-01',
  );
}

CustomerInfo buildFreeCustomer() {
  return CustomerInfo(
    const EntitlementInfos({}, {}),
    const {},
    const [],
    const [],
    const [],
    '2026-01-01',
    'orig-user',
    const {},
    '2026-01-01',
  );
}
