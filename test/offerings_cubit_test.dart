import 'package:grammarfix/features/subscriptions/presentation/cubits/offerings_cubit.dart';
import 'package:grammarfix/features/subscriptions/presentation/cubits/offerings_states.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'fakes/fake_offerings.dart';

void main() {
  test('loadOfferings maps monthly then annual from the current offering',
      () async {
    final monthly = buildPackage('monthly', PackageType.monthly, r'$4.99');
    final annual = buildPackage('annual', PackageType.annual, r'$49.99');
    final cubit = OfferingsCubit(
      fetchOfferings: () async =>
          buildOfferings(buildOffering(monthly: monthly, annual: annual)),
    );

    await cubit.loadOfferings();

    expect(cubit.state, isA<OfferingsLoaded>());
    final packages = (cubit.state as OfferingsLoaded)
        .packages
        .whereType<Package>()
        .toList();
    expect(packages, hasLength(2));
    expect(packages[0].packageType, PackageType.monthly);
    expect(packages[1].packageType, PackageType.annual);
  });

  test('loadOfferings handles no offerings as empty loaded state', () async {
    final cubit = OfferingsCubit(fetchOfferings: () async => null);

    await cubit.loadOfferings();

    expect(cubit.state, isA<OfferingsLoaded>());
    expect((cubit.state as OfferingsLoaded).packages, isEmpty);
  });

  test('loadOfferings emits error when the fetch throws', () async {
    final cubit = OfferingsCubit(
      fetchOfferings: () async => throw Exception('network'),
    );

    await cubit.loadOfferings();

    expect(cubit.state, isA<OfferingsError>());
  });

  test('purchasePackage calls onSuccess for an active pro entitlement',
      () async {
    final monthly = buildPackage('monthly', PackageType.monthly, r'$4.99');
    var successCalled = false;
    final cubit = OfferingsCubit(
      fetchOfferings: () async =>
          buildOfferings(buildOffering(monthly: monthly)),
      purchasePackage: (_) async => buildProCustomer(),
    );

    await cubit.loadOfferings();
    await cubit.purchasePackage(monthly, () => successCalled = true);

    expect(successCalled, isTrue);
  });

  test('purchasePackage reverts to loaded state when cancelled', () async {
    final monthly = buildPackage('monthly', PackageType.monthly, r'$4.99');
    final cubit = OfferingsCubit(
      fetchOfferings: () async =>
          buildOfferings(buildOffering(monthly: monthly)),
      purchasePackage: (_) async => buildFreeCustomer(),
    );
    await cubit.loadOfferings();

    await cubit.purchasePackage(monthly, () {});

    expect(cubit.state, isA<OfferingsLoaded>());
  });

  test('purchasePackage emits PurchaseError on failure', () async {
    final monthly = buildPackage('monthly', PackageType.monthly, r'$4.99');
    final cubit = OfferingsCubit(
      fetchOfferings: () async =>
          buildOfferings(buildOffering(monthly: monthly)),
      purchasePackage: (_) async => throw Exception('purchase failed'),
    );

    await cubit.purchasePackage(monthly, () {});

    expect(cubit.state, isA<PurchaseError>());
  });
}
