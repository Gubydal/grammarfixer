import 'dart:async';

import 'package:app_starter/features/subscriptions/presentation/cubits/offerings_cubit.dart';
import 'package:app_starter/features/subscriptions/presentation/cubits/subscription_cubit.dart';
import 'package:app_starter/features/subscriptions/presentation/pages/offerings_page.dart';
import 'package:app_starter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'fakes/fake_offerings.dart';

Widget _wrap({
  required OfferingsCubit offeringsCubit,
  required SubscriptionCubit subscriptionCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<OfferingsCubit>(create: (_) => offeringsCubit),
      BlocProvider<SubscriptionCubit>(create: (_) => subscriptionCubit),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SafeArea(child: PaywallView())),
    ),
  );
}

void main() {
  testWidgets('shows monthly/annual plan cards with localized prices', (
    tester,
  ) async {
    final monthly = buildPackage('monthly', PackageType.monthly, r'$4.99');
    final annual = buildPackage('annual', PackageType.annual, r'$49.99');
    final offeringsCubit = OfferingsCubit(
      fetchOfferings: () async =>
          buildOfferings(buildOffering(monthly: monthly, annual: annual)),
    );
    final subscriptionCubit = SubscriptionCubit(
      attachRevenueCatListener: false,
      isProCheck: () async => false,
    );

    await tester.pumpWidget(
      _wrap(offeringsCubit: offeringsCubit, subscriptionCubit: subscriptionCubit),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    expect(find.text(r'$4.99'), findsOneWidget);
    // Annual price appears on the card, in the CTA, and under the CTA.
    expect(find.text(r'$49.99'), findsWidgets);
    // Annual is the default recommended plan.
    expect(find.text('Best value'), findsOneWidget);
    expect(find.textContaining('Start Pro'), findsOneWidget);
    expect(find.textContaining(r'$49.99'), findsWidgets);
  });

  testWidgets('handles no offerings with a friendly empty state', (
    tester,
  ) async {
    final offeringsCubit = OfferingsCubit(fetchOfferings: () async => null);
    final subscriptionCubit = SubscriptionCubit(
      attachRevenueCatListener: false,
      isProCheck: () async => false,
    );

    await tester.pumpWidget(
      _wrap(offeringsCubit: offeringsCubit, subscriptionCubit: subscriptionCubit),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Configure an offering in RevenueCat to enable Pro.'),
      findsOneWidget,
    );
  });

  testWidgets('shows active Pro state instead of the purchase CTA', (
    tester,
  ) async {
    final offeringsCubit = OfferingsCubit(
      fetchOfferings: () async =>
          buildOfferings(buildOffering(monthly: buildPackage('monthly', PackageType.monthly, r'$4.99'))),
    );
    final subscriptionCubit = SubscriptionCubit(
      attachRevenueCatListener: false,
      isProCheck: () async => true,
    )..checkProStatus();

    await tester.pumpWidget(
      _wrap(offeringsCubit: offeringsCubit, subscriptionCubit: subscriptionCubit),
    );
    await tester.pumpAndSettle();

    expect(find.text("You're Pro"), findsOneWidget);
    expect(find.textContaining('Start Pro'), findsNothing);
  });

  testWidgets('renders loading state before offerings resolve', (
    tester,
  ) async {
    final completer = Completer<Offerings?>();
    final offeringsCubit = OfferingsCubit(fetchOfferings: () => completer.future);
    final subscriptionCubit = SubscriptionCubit(
      attachRevenueCatListener: false,
      isProCheck: () async => false,
    );

    await tester.pumpWidget(
      _wrap(offeringsCubit: offeringsCubit, subscriptionCubit: subscriptionCubit),
    );
    await tester.pump();

    expect(find.text('Loading offers…'), findsOneWidget);
    completer.complete(null);
    await tester.pumpAndSettle();
  });
}
