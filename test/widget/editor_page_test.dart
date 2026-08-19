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
import 'package:grammarfix/features/correction/domain/services/typo_candidate_engine.dart';
import 'package:grammarfix/features/correction/presentation/cubits/correction_cubit.dart';
import 'package:grammarfix/features/correction/presentation/cubits/model_pack_cubit.dart';
import 'package:grammarfix/features/correction/presentation/pages/editor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EditorPage Widget Tests', () {
    late CorrectionRepository correctionRepo;
    late ModelPackRepository modelPackRepo;
    late DraftRepository draftRepo;
    late PersonalStyleRepository personalStyleRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      modelPackRepo = ModelPackRepository(prefs: prefs);
      draftRepo = DraftRepository(prefs: prefs);
      personalStyleRepo = PersonalStyleRepository(prefs);

      correctionRepo = CorrectionRepository(
        harperEngine: HarperEngine(),
        multilingualEngine: MultilingualEngine(),
        languageDetector: const LanguageDetector(),
        customDictionaryRepo: CustomDictionaryRepository(prefs: prefs),
        modelPackRepo: modelPackRepo,
        personalStyleRepo: personalStyleRepo,
        typoCandidateEngine: TypoCandidateEngine(),
      );
    });

    Widget createTestWidget() {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: correctionRepo),
          RepositoryProvider.value(value: modelPackRepo),
          RepositoryProvider.value(value: draftRepo),
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
            BlocProvider(
              create: (_) => ModelPackCubit(repository: modelPackRepo),
            ),
          ],
          child: MaterialApp(
            theme: lightMode,
            home: const EditorPage(),
          ),
        ),
      );
    }

    testWidgets('renders EditorPage with title, placeholder, and action buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('GrammarFix'), findsOneWidget);
      expect(find.text('On-device'), findsOneWidget);
      expect(find.text('Paste or type text to fix grammar, typos, and punctuation…'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Correct'), findsNWidgets(2)); // Button in header switcher and bottom CTA
    });

    testWidgets('typing text and clicking Correct transitions to review mode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'He don\'t know the answer.');
      await tester.pumpAndSettle();

      final correctButton = find.widgetWithText(ElevatedButton, 'Correct');
      if (correctButton.evaluate().isNotEmpty) {
        await tester.tap(correctButton);
      } else {
        // AppButton custom widget
        final appButton = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'AppButton' && find.text('Correct').evaluate().isNotEmpty);
        await tester.tap(appButton.last);
      }
      await tester.pumpAndSettle();

      expect(find.textContaining('found'), findsOneWidget);
      expect(find.text('Fix all (1 issue)'), findsOneWidget);
    });
  });
}
