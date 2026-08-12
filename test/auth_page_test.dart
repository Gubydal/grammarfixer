import 'package:app_starter/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:app_starter/features/auth/presentation/pages/auth_page.dart';
import 'package:app_starter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repo.dart';

Widget _wrap(Widget child) {
  return BlocProvider(
    create: (_) => AuthCubit(authRepo: FakeAuthRepo()),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('login validates empty fields', (tester) async {
    await tester.pumpWidget(_wrap(const AuthPage()));

    await tester.ensureVisible(find.text('Sign In with Email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In with Email'));
    await tester.pump();

    expect(
      find.text('Please enter both email & password.'),
      findsOneWidget,
    );
  });
}
