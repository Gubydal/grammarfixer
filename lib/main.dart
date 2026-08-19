import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/secure_local_storage.dart';
import 'core/services/play_services.dart';
import 'design/app_theme.dart';
import 'features/ads/data/ad_service.dart';
import 'features/correction/data/repositories/correction_repository.dart';
import 'features/correction/data/repositories/custom_dictionary_repository.dart';
import 'features/correction/data/repositories/draft_repository.dart';
import 'features/correction/data/repositories/model_pack_repository.dart';
import 'features/correction/data/repositories/personal_style_repository.dart';
import 'features/correction/domain/services/harper_engine.dart';
import 'features/correction/domain/services/language_detector.dart';
import 'features/correction/domain/services/multilingual_engine.dart';
import 'features/correction/domain/services/typo_candidate_engine.dart';
import 'features/correction/presentation/cubits/correction_cubit.dart';
import 'features/correction/presentation/cubits/custom_dictionary_cubit.dart';
import 'features/correction/presentation/cubits/model_pack_cubit.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/shell/presentation/main_shell.dart';
import 'features/subscriptions/data/revenuecat_service.dart';
import 'features/subscriptions/presentation/cubits/offerings_cubit.dart';
import 'features/subscriptions/presentation/cubits/subscription_cubit.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(const FlutterSecureStorage()),
      ),
    );
  } catch (_) {
    // App operates 100% offline without Supabase
  }

  try {
    await RevenuecatService.configureRevenueCat(AppConfig.revenueCatApiKey);
  } catch (_) {}

  try {
    await AdService.instance.initialize();
  } catch (_) {}

  // Domain Services & Repositories
  final harperEngine = HarperEngine();
  final multilingualEngine = MultilingualEngine();
  final typoEngine = TypoCandidateEngine();
  const languageDetector = LanguageDetector();

  final customDictionaryRepo = CustomDictionaryRepository(prefs: prefs);
  final draftRepo = DraftRepository(prefs: prefs);
  final modelPackRepo = ModelPackRepository(prefs: prefs);
  final personalStyleRepo = PersonalStyleRepository(prefs);

  final correctionRepo = CorrectionRepository(
    harperEngine: harperEngine,
    multilingualEngine: multilingualEngine,
    languageDetector: languageDetector,
    customDictionaryRepo: customDictionaryRepo,
    modelPackRepo: modelPackRepo,
    personalStyleRepo: personalStyleRepo,
    typoCandidateEngine: typoEngine,
  );

  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xFFF8FBF8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong.\n\n${details.exception}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF17231B)),
          ),
        ),
      ),
    );
  };

  runApp(
    GrammarFixApp(
      prefs: prefs,
      correctionRepo: correctionRepo,
      customDictionaryRepo: customDictionaryRepo,
      draftRepo: draftRepo,
      modelPackRepo: modelPackRepo,
      personalStyleRepo: personalStyleRepo,
      onboardingCompleted: onboardingCompleted,
    ),
  );
}

class GrammarFixApp extends StatefulWidget {
  const GrammarFixApp({
    super.key,
    required this.prefs,
    required this.correctionRepo,
    required this.customDictionaryRepo,
    required this.draftRepo,
    required this.modelPackRepo,
    required this.personalStyleRepo,
    required this.onboardingCompleted,
  });

  final SharedPreferences prefs;
  final CorrectionRepository correctionRepo;
  final CustomDictionaryRepository customDictionaryRepo;
  final DraftRepository draftRepo;
  final ModelPackRepository modelPackRepo;
  final PersonalStyleRepository personalStyleRepo;
  final bool onboardingCompleted;

  @override
  State<GrammarFixApp> createState() => _GrammarFixAppState();
}

class _GrammarFixAppState extends State<GrammarFixApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(PlayServices.checkForUpdate());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CorrectionRepository>.value(value: widget.correctionRepo),
        RepositoryProvider<CustomDictionaryRepository>.value(value: widget.customDictionaryRepo),
        RepositoryProvider<DraftRepository>.value(value: widget.draftRepo),
        RepositoryProvider<ModelPackRepository>.value(value: widget.modelPackRepo),
        RepositoryProvider<PersonalStyleRepository>.value(value: widget.personalStyleRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CorrectionCubit>(
            create: (context) => CorrectionCubit(
              repository: widget.correctionRepo,
              modelPackRepository: widget.modelPackRepo,
              draftRepository: widget.draftRepo,
              personalStyleRepository: widget.personalStyleRepo,
            ),
          ),
          BlocProvider<ModelPackCubit>(
            create: (context) => ModelPackCubit(
              repository: widget.modelPackRepo,
            ),
          ),
          BlocProvider<CustomDictionaryCubit>(
            create: (context) => CustomDictionaryCubit(
              repository: widget.customDictionaryRepo,
            ),
          ),
          BlocProvider<SubscriptionCubit>(
            create: (context) => SubscriptionCubit(
              forcePro: AppConfig.forcePro,
            ),
          ),
          BlocProvider<OfferingsCubit>(
            create: (context) => OfferingsCubit(),
          ),
        ],
        child: MaterialApp(
          title: AppConfig.appName,
          theme: lightMode,
          darkTheme: darkMode,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget.onboardingCompleted ? const MainShell() : const OnboardingPage(),
        ),
      ),
    );
  }
}
