import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/design/components/app_bottom_bar.dart';
import 'package:grammarfix/features/correction/data/repositories/correction_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/draft_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/model_pack_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';
import 'package:grammarfix/features/correction/presentation/cubits/correction_cubit.dart';
import 'package:grammarfix/features/correction/presentation/cubits/custom_dictionary_cubit.dart';
import 'package:grammarfix/features/correction/presentation/cubits/model_pack_cubit.dart';
import 'package:grammarfix/features/shell/presentation/main_shell.dart';
import 'package:grammarfix/features/subscriptions/presentation/cubits/offerings_cubit.dart';
import 'package:grammarfix/features/subscriptions/presentation/cubits/subscription_cubit.dart';
import 'package:grammarfix/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(SharedPreferences prefs) {
  final modelPackRepo = ModelPackRepository(prefs: prefs);
  final draftRepo = DraftRepository(prefs: prefs);
  final dictionaryRepo = CustomDictionaryRepository(prefs: prefs);
  final personalStyleRepo = PersonalStyleRepository(prefs);
  final correctionRepo = CorrectionRepository(
    harperEngine: HarperEngine(),
    multilingualEngine: MultilingualEngine(),
    languageDetector: const LanguageDetector(),
    customDictionaryRepo: dictionaryRepo,
    modelPackRepo: modelPackRepo,
    personalStyleRepo: personalStyleRepo,
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: correctionRepo),
      RepositoryProvider.value(value: modelPackRepo),
      RepositoryProvider.value(value: draftRepo),
      RepositoryProvider.value(value: dictionaryRepo),
      RepositoryProvider.value(value: personalStyleRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CorrectionCubit(
            repository: correctionRepo,
            modelPackRepository: modelPackRepo,
            draftRepository: draftRepo,
            personalStyleRepository: personalStyleRepo,
          ),
        ),
        BlocProvider(create: (_) => ModelPackCubit(repository: modelPackRepo)),
        BlocProvider(create: (_) => CustomDictionaryCubit(repository: dictionaryRepo)),
        BlocProvider(create: (_) => SubscriptionCubit(forcePro: true)),
        BlocProvider(create: (_) => OfferingsCubit()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainShell(),
      ),
    ),
  );
}

void main() {
  testWidgets('paints the floating bottom bar and correct tab', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_wrap(prefs));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomBar), findsOneWidget);
    expect(find.text('GrammarFix'), findsOneWidget);
    expect(find.text('Paste or type text to fix grammar, typos, and punctuation…'), findsOneWidget);
  });

  testWidgets('switching tabs switches screens correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_wrap(prefs));
    await tester.pumpAndSettle();

    // Click Settings tab via semantics label
    final settingsDestination = find.bySemanticsLabel('Settings');
    expect(settingsDestination, findsOneWidget);
    await tester.tap(settingsDestination);
    await tester.pumpAndSettle();

    expect(find.text('WRITING'), findsOneWidget);
    expect(find.text('English Variant'), findsOneWidget);

    // Click Correct tab via semantics label
    final correctDestination = find.bySemanticsLabel('Correct');
    expect(correctDestination, findsOneWidget);
    await tester.tap(correctDestination);
    await tester.pumpAndSettle();

    expect(find.text('GrammarFix'), findsOneWidget);
  });
}
