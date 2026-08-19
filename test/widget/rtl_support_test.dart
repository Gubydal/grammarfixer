import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/data/repositories/correction_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/draft_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/model_pack_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/entities/correction_issue.dart';
import 'package:grammarfix/features/correction/domain/entities/correction_result.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';
import 'package:grammarfix/features/correction/domain/services/typo_candidate_engine.dart';
import 'package:grammarfix/features/correction/presentation/cubits/correction_cubit.dart';
import 'package:grammarfix/features/correction/presentation/cubits/correction_state.dart';
import 'package:grammarfix/features/correction/presentation/pages/review_mode_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Arabic RTL Support Tests', () {
    late CorrectionRepository repo;
    late DraftRepository draftRepo;
    late ModelPackRepository modelPackRepo;
    late PersonalStyleRepository personalStyleRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      draftRepo = DraftRepository(prefs: prefs);
      modelPackRepo = ModelPackRepository(prefs: prefs);
      personalStyleRepo = PersonalStyleRepository(prefs);
      repo = CorrectionRepository(
        harperEngine: HarperEngine(),
        multilingualEngine: MultilingualEngine(),
        languageDetector: const LanguageDetector(),
        customDictionaryRepo: CustomDictionaryRepository(prefs: prefs),
        modelPackRepo: modelPackRepo,
        personalStyleRepo: personalStyleRepo,
        typoCandidateEngine: TypoCandidateEngine(),
      );
    });

    testWidgets('ReviewModeView renders with TextDirection.rtl for Arabic content', (tester) async {
      final arabicResult = CorrectionResult(
        sourceText: 'هذه كتاب مفيد',
        sourceHash: 12345,
        sourceRevision: 1,
        correctedText: 'هذا كتاب مفيد',
        issues: const [
          CorrectionIssue(
            id: 'ar_01',
            engine: 'qwen',
            category: IssueCategory.grammar,
            severity: IssueSeverity.warning,
            start: 0,
            end: 3,
            original: 'هذه',
            suggestions: ['هذا'],
            message: 'تصحيح اسم الإشارة',
          ),
        ],
        language: AppLanguage.arabic,
        engineName: 'Qwen',
      );

      final reviewState = CorrectionReview(
        sourceText: 'هذه كتاب مفيد',
        currentText: 'هذه كتاب مفيد',
        result: arabicResult,
        issues: arabicResult.issues,
        language: AppLanguage.arabic,
      );

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: repo),
            RepositoryProvider.value(value: draftRepo),
            RepositoryProvider.value(value: modelPackRepo),
            RepositoryProvider.value(value: personalStyleRepo),
          ],
          child: BlocProvider(
            create: (_) => CorrectionCubit(
              repository: repo,
              modelPackRepository: modelPackRepo,
              draftRepository: draftRepo,
              personalStyleRepository: personalStyleRepo,
            ),
            child: MaterialApp(
              home: ReviewModeView(state: reviewState),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final directionalityFinder = find.byWidgetPredicate(
        (widget) => widget is Directionality && widget.textDirection == TextDirection.rtl,
      );
      expect(directionalityFinder, findsWidgets);
      expect(find.text('Fix all (1 issue)'), findsOneWidget);
    });
  });
}
