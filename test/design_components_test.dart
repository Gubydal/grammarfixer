import 'package:app_starter/design/components/app_bottom_bar.dart';
import 'package:app_starter/design/components/app_button.dart';
import 'package:app_starter/design/components/app_state_view.dart';
import 'package:app_starter/design/components/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton renders variants and loading state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton(
                label: 'Filled',
                onPressed: () {},
                variant: AppButtonVariant.filled,
              ),
              AppButton(
                label: 'Outlined',
                onPressed: () {},
                variant: AppButtonVariant.outlined,
              ),
              const AppButton(label: 'Loading', onPressed: null, loading: true),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsWidgets);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppTextField shows label and error text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: TextEditingController(),
            hintText: 'Hint',
            label: 'Email',
            errorText: 'Required',
          ),
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('AppBottomBar reports the selected destination', (tester) async {
    const destinations = [
      AppBottomDestination(icon: 'home', label: 'Home'),
      AppBottomDestination(icon: 'profile', label: 'Profile'),
    ];
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AppBottomBar(
              currentIndex: selected,
              destinations: destinations,
              onDestinationSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomBar),
        matching: find.bySemanticsLabel('Profile'),
      ),
    );
    await tester.pump();

    expect(selected, 1);
  });

  testWidgets('state views render their messages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const LoadingStateView(message: 'Loading data'),
              const EmptyStateView(
                icon: Icons.inbox,
                title: 'Nothing here',
                message: 'Add something',
              ),
              const ErrorStateView(message: 'Failed'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Loading data'), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
  });
}
