import 'package:app_starter/features/auth/domain/entities/app_user.dart';
import 'package:app_starter/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:app_starter/features/shell/presentation/main_shell.dart';
import 'package:app_starter/features/subscriptions/presentation/cubits/offerings_cubit.dart';
import 'package:app_starter/features/subscriptions/presentation/cubits/subscription_cubit.dart';
import 'package:app_starter/design/components/app_bottom_bar.dart';
import 'package:app_starter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repo.dart';

Widget _wrap() {
  final authCubit = AuthCubit(
    authRepo: FakeAuthRepo()
      ..currentUser = AppUser(
        uid: '1',
        email: 'user@example.com',
        displayName: 'Test User',
      ),
  )..checkAuth();
  final subscriptionCubit = SubscriptionCubit(
    attachRevenueCatListener: false,
    isProCheck: () async => true,
  )..checkProStatus();
  final offeringsCubit = OfferingsCubit(fetchOfferings: () async => null);

  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>(create: (_) => authCubit),
      BlocProvider<SubscriptionCubit>(create: (_) => subscriptionCubit),
      BlocProvider<OfferingsCubit>(create: (_) => offeringsCubit),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainShell(),
    ),
  );
}

void main() {
  testWidgets('paints the floating bottom bar and home content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomBar), findsOneWidget);
    expect(find.textContaining('Welcome to'), findsOneWidget);
    expect(find.text('You are Pro'), findsOneWidget);
  });

  testWidgets('navigates between tabs', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.bySemanticsLabel('Profile'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.bySemanticsLabel('Settings'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Send Feedback'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.bySemanticsLabel('Upgrade'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Configure an offering in RevenueCat to enable Pro.'),
      findsOneWidget,
    );
  });
}
