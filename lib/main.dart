import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/config/app_config.dart';
import 'core/config/secure_local_storage.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/play_services.dart';
import 'design/app_theme.dart';
import 'features/ads/data/ad_service.dart';
import 'features/auth/data/supabase_auth_repo.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/cubits/auth_states.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/shell/presentation/main_shell.dart';
import 'features/subscriptions/data/revenuecat_service.dart';
import 'features/subscriptions/presentation/cubits/offerings_cubit.dart';
import 'features/subscriptions/presentation/cubits/subscription_cubit.dart';
import 'features/subscriptions/presentation/cubits/subscription_states.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(const FlutterSecureStorage()),
    ),
  );

  await RevenuecatService.configureRevenueCat(AppConfig.revenueCatApiKey);
  await AdService.instance.initialize();

  // Supabase emits this event when the user opens the password-reset deep link.
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => const ResetPasswordPage(),
        ),
      );
    }
  });

  // Replace Flutter's opaque gray error surface with a readable message so
  // unexpected build errors are visible instead of a blank screen.
  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xFFFDF7F7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong.\n\n${details.exception}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AdService.instance.showAppOpenAdIfAvailable());
    }
  }

  @override
  Widget build(BuildContext context) {
    // All app-level cubits live ABOVE MaterialApp so pushed routes
    // (settings, feedback, paywall) can read them.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => SupabaseAuthRepo(
            Supabase.instance.client,
          ).let((repo) => AuthCubit(authRepo: repo)..checkAuth()),
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
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: AppConfig.appName,
        theme: lightMode,
        darkTheme: darkMode,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocListener<SubscriptionCubit, SubscriptionState>(
          listener: (context, state) {
            if (state is SubscriptionLoaded) {
              AdService.instance.setProStatus(state.isPro);
            }
          },
          child: BlocConsumer<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading || state is AuthInitial) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is Unauthenticated) {
                return const AuthPage();
              }
              return const MainShell();
            },
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
              if (state is Authenticated) {
                context.read<SubscriptionCubit>().checkProStatus();
              }
            },
          ),
        ),
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T value) transform) => transform(this);
}
