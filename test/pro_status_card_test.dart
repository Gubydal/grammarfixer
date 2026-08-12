import 'package:app_starter/features/home/presentation/components/pro_status_card.dart';
import 'package:app_starter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('shows upgrade CTA for free users', (tester) async {
    await tester.pumpWidget(_wrap(const ProStatusCard(isPro: false)));

    expect(find.text('Go Pro'), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);
  });

  testWidgets('shows Pro state for subscribers', (tester) async {
    await tester.pumpWidget(_wrap(const ProStatusCard(isPro: true)));

    expect(find.text('You are Pro'), findsOneWidget);
    expect(find.text('Go Pro'), findsNothing);
  });
}
