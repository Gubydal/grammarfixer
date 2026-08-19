import 'package:purchases_flutter/purchases_flutter.dart';

Package buildPackage(String identifier, PackageType type, String priceString) {
  final product = StoreProduct(
    identifier,
    'GrammarFix Pro',
    'Pro Plan',
    4.99,
    priceString,
    'USD',
  );
  return Package(
    identifier,
    type,
    product,
    const PresentedOfferingContext('default', null, null),
  );
}

Offering buildOffering({Package? monthly, Package? annual}) {
  final packages = <Package>[
    ?monthly,
    ?annual,
  ];
  return Offering(
    'default',
    'Default Offering',
    {},
    packages,
    monthly: monthly,
    annual: annual,
  );
}

Offerings buildOfferings([Offering? current]) {
  final off = current ?? buildOffering();
  return Offerings({off.identifier: off}, current: off);
}

CustomerInfo buildProCustomer() {
  return CustomerInfo.fromJson({
    'entitlements': {
      'all': {
        'pro': {
          'identifier': 'pro',
          'isActive': true,
          'willRenew': true,
          'periodType': 'NORMAL',
          'latestPurchaseDateMillis': 1700000000000,
          'latestPurchaseDate': '2026-01-01T00:00:00Z',
          'originalPurchaseDateMillis': 1700000000000,
          'originalPurchaseDate': '2026-01-01T00:00:00Z',
          'expirationDateMillis': 4000000000000,
          'expirationDate': '2099-01-01T00:00:00Z',
          'store': 'PLAY_STORE',
          'productIdentifier': 'pro_monthly',
          'isSandbox': true,
          'unsubscribeDetectedAt': null,
          'unsubscribeDetectedAtMillis': null,
          'billingIssueDetectedAt': null,
          'billingIssueDetectedAtMillis': null,
          'ownershipType': 'PURCHASED',
        }
      },
      'active': {
        'pro': {
          'identifier': 'pro',
          'isActive': true,
          'willRenew': true,
          'periodType': 'NORMAL',
          'latestPurchaseDateMillis': 1700000000000,
          'latestPurchaseDate': '2026-01-01T00:00:00Z',
          'originalPurchaseDateMillis': 1700000000000,
          'originalPurchaseDate': '2026-01-01T00:00:00Z',
          'expirationDateMillis': 4000000000000,
          'expirationDate': '2099-01-01T00:00:00Z',
          'store': 'PLAY_STORE',
          'productIdentifier': 'pro_monthly',
          'isSandbox': true,
          'unsubscribeDetectedAt': null,
          'unsubscribeDetectedAtMillis': null,
          'billingIssueDetectedAt': null,
          'billingIssueDetectedAtMillis': null,
          'ownershipType': 'PURCHASED',
        }
      }
    },
    'allPurchaseDates': {},
    'allPurchaseDatesMillis': {},
    'allExpirationDates': {},
    'allExpirationDatesMillis': {},
    'activeSubscriptions': ['pro_monthly'],
    'allPurchasedProductIdentifiers': ['pro_monthly'],
    'nonSubscriptionTransactions': [],
    'firstSeen': '2026-01-01T00:00:00Z',
    'firstSeenMillis': 1700000000000,
    'originalAppUserId': 'app_user_1',
    'requestDate': '2026-01-01T00:00:00Z',
    'requestDateMillis': 1700000000000,
    'originalPurchaseDate': null,
    'originalPurchaseDateMillis': null,
    'managementURL': null,
  });
}

CustomerInfo buildFreeCustomer() {
  return CustomerInfo.fromJson({
    'entitlements': {
      'all': {},
      'active': {},
    },
    'allPurchaseDates': {},
    'allPurchaseDatesMillis': {},
    'allExpirationDates': {},
    'allExpirationDatesMillis': {},
    'activeSubscriptions': [],
    'allPurchasedProductIdentifiers': [],
    'nonSubscriptionTransactions': [],
    'firstSeen': '2026-01-01T00:00:00Z',
    'firstSeenMillis': 1700000000000,
    'originalAppUserId': 'app_user_1',
    'requestDate': '2026-01-01T00:00:00Z',
    'requestDateMillis': 1700000000000,
    'originalPurchaseDate': null,
    'originalPurchaseDateMillis': null,
    'managementURL': null,
  });
}
