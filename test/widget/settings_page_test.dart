import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/design/app_theme.dart';
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
import 'package:grammarfix/features/settings/presentation/pages/settings_page.dart';
import 'package:grammarfix/features/subscriptions/presentation/cubits/subscription_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsPage Widget Tests', () {
    late ModelPackRepository modelPackRepo;
    late DraftRepository draftRepo;
    late CustomDictionaryRepository dictionaryRepo;
    late PersonalStyleRepository personalStyleRepo;
    late CorrectionRepository correctionRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      modelPackRepo = ModelPackRepository(prefs: prefs);
      draftRepo = DraftRepository(prefs: prefs);
      dictionaryRepo = CustomDictionaryRepository(prefs: prefs);
      personalStyleRepo = PersonalStyleRepository(prefs);

      correctionRepo = CorrectionRepository(
        harperEngine: HarperEngine(),
        multilingualEngine: MultilingualEngine(),
        languageDetector: const LanguageDetector(),
        customDictionaryRepo: dictionaryRepo,
        modelPackRepo: modelPackRepo,
        personalStyleRepo: personalStyleRepo,
      );
    });

    testWidgets('renders all settings sections', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: modelPackRepo),
            RepositoryProvider.value(value: draftRepo),
            RepositoryProvider.value(value: dictionaryRepo),
            RepositoryProvider.value(value: personalStyleRepo),
            RepositoryProvider.value(value: correctionRepo),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => ModelPackCubit(repository: modelPackRepo)),
              BlocProvider(create: (_) => CustomDictionaryCubit(repository: dictionaryRepo)),
              BlocProvider(create: (_) => SubscriptionCubit(forcePro: true)),
              BlocProvider(
                create: (_) => CorrectionCubit(
                  repository: correctionRepo,
                  modelPackRepository: modelPackRepo,
                  draftRepository: draftRepo,
                  personalStyleRepository: personalStyleRepo,
                ),
              ),
            ],
            child: MaterialApp(
              theme: lightMode,
              home: const SettingsPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('WRITING'), findsOneWidget);
      expect(find.text('English Variant'), findsOneWidget);
      expect(find.text('Custom Dictionary'), findsOneWidget);
      expect(find.text('Personal Style'), findsOneWidget);
      expect(find.text('WRITING EVERYWHERE'), findsOneWidget);
      expect(find.text('System Grammar Checker'), findsOneWidget);
      expect(find.text('OFFLINE LANGUAGES'), findsOneWidget);
      expect(find.text('Multilingual Model Pack'), findsOneWidget);
      expect(find.text('PRIVACY & STORAGE'), findsOneWidget);
      expect(find.text('MEMBERSHIP'), findsOneWidget);
      expect(find.text('SUPPORT & APP INFO'), findsOneWidget);
    });
  });
}
