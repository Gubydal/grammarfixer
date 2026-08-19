import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/design/app_theme.dart';
import 'package:grammarfix/features/correction/data/repositories/correction_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/model_pack_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';
import 'package:grammarfix/features/correction/domain/services/typo_candidate_engine.dart';
import 'package:grammarfix/features/correction/presentation/pages/process_text_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProcessTextPage Widget Tests', () {
    late CorrectionRepository correctionRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      correctionRepo = CorrectionRepository(
        harperEngine: HarperEngine(),
        multilingualEngine: MultilingualEngine(),
        languageDetector: const LanguageDetector(),
        customDictionaryRepo: CustomDictionaryRepository(prefs: prefs),
        modelPackRepo: ModelPackRepository(prefs: prefs),
        personalStyleRepo: PersonalStyleRepository(prefs),
        typoCandidateEngine: TypoCandidateEngine(),
      );
    });

    testWidgets('renders process text dialog and corrects input text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightMode,
          home: Scaffold(
            body: ProcessTextPage(
              correctionRepository: correctionRepo,
              initialText: 'He don\'t know the secret.',
              isReadOnly: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fix Grammar'), findsOneWidget);
      expect(find.text('He doesn\'t know the secret.'), findsOneWidget);
      expect(find.text('Apply to text'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('read-only selection hides Apply to text button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightMode,
          home: Scaffold(
            body: ProcessTextPage(
              correctionRepository: correctionRepo,
              initialText: 'The weather is good.',
              isReadOnly: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Apply to text'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
    });
  });
}
