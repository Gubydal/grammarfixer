import 'package:flutter_test/flutter_test.dart';
import 'package:grammarfix/features/correction/data/repositories/correction_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/custom_dictionary_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/model_pack_repository.dart';
import 'package:grammarfix/features/correction/data/repositories/personal_style_repository.dart';
import 'package:grammarfix/features/correction/domain/entities/language.dart';
import 'package:grammarfix/features/correction/domain/services/english_context_rules.dart';
import 'package:grammarfix/features/correction/domain/services/harper_engine.dart';
import 'package:grammarfix/features/correction/domain/services/language_detector.dart';
import 'package:grammarfix/features/correction/domain/services/multilingual_engine.dart';
import 'package:grammarfix/features/correction/domain/services/typo_candidate_engine.dart';
import 'package:grammarfix/features/correction/domain/services/writing_style_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CorrectionRepository repository;
  late EnglishContextRules contextRules;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final customDictRepo = CustomDictionaryRepository(prefs: prefs);
    final modelPackRepo = ModelPackRepository(prefs: prefs);
    final personalStyleRepo = PersonalStyleRepository(prefs);

    contextRules = const EnglishContextRules();

    repository = CorrectionRepository(
      harperEngine: HarperEngine(),
      multilingualEngine: MultilingualEngine(),
      languageDetector: const LanguageDetector(),
      customDictionaryRepo: customDictRepo,
      modelPackRepo: modelPackRepo,
      personalStyleRepo: personalStyleRepo,
      typoCandidateEngine: TypoCandidateEngine(),
      contextRules: contextRules,
      styleEngine: const WritingStyleEngine(),
    );
  });

  test('ESL Prepositions and Gerunds are accurately detected and corrected', () async {
    // 1. "depends of" -> "depends on"
    final r1 = await repository.correct(text: 'It depends of the weather.', selectedLanguage: AppLanguage.english);
    expect(r1.correctedText, equals('It depends on the weather.'));

    // 2. "married with" -> "married to"
    final r2 = await repository.correct(text: 'She is married with a doctor.', selectedLanguage: AppLanguage.english);
    expect(r2.correctedText, equals('She is married to a doctor.'));

    // 3. "good in math" -> "good at math"
    final r3 = await repository.correct(text: 'He is good in math.', selectedLanguage: AppLanguage.english);
    expect(r3.correctedText, equals('He is good at math.'));

    // 4. "look forward to meet" -> "look forward to meeting"
    final r4 = await repository.correct(text: 'I look forward to meet you.', selectedLanguage: AppLanguage.english);
    expect(r4.correctedText, equals('I look forward to meeting you.'));
  });

  test('Uncountable nouns and article rules are accurately corrected', () async {
    // 1. "advices" -> "advice"
    final r1 = await repository.correct(text: 'He gave me many advices.', selectedLanguage: AppLanguage.english);
    expect(r1.correctedText.contains('advice'), isTrue);

    // 2. "an university" -> "a university"
    final r2 = await repository.correct(text: 'She attends an university in Paris.', selectedLanguage: AppLanguage.english);
    expect(r2.correctedText, equals('She attends a university in Paris.'));

    // 3. "a hour" -> "an hour"
    final r3 = await repository.correct(text: 'Wait for a hour please.', selectedLanguage: AppLanguage.english);
    expect(r3.correctedText, equals('Wait for an hour please.'));

    // 4. "go to home" -> "go home"
    final r4 = await repository.correct(text: 'I want to go to home now.', selectedLanguage: AppLanguage.english);
    expect(r4.correctedText, equals('I want to go home now.'));
  });
}
