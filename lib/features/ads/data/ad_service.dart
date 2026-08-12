import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';

/// Central AdMob manager.
///
/// Ads are suppressed for Pro users, on trust-sensitive screens (handled by
/// the UI), and during onboarding/auth/paywall flows (handled by callers).
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  bool _initialized = false;
  bool _isPro = false;
  AppOpenAd? _appOpenAd;
  DateTime? _lastAppOpenShown;

  static const Duration _appOpenCooldown = Duration(minutes: 4);

  static const String _lastInterstitialKey = 'last_interstitial_at';
  static const String _pendingInterstitialCountKey =
      'interstitial_pending_count';

  bool get isPro => _isPro;

  void setProStatus(bool value) {
    _isPro = value;
    if (value) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await MobileAds.instance.initialize();
    await _requestConsent();
    await _loadAppOpenAd();
  }

  Future<void> _requestConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        }
        if (!completer.isCompleted) completer.complete();
      },
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
  }

  Future<void> _loadAppOpenAd() async {
    if (_isPro) return;
    await AppOpenAd.load(
      adUnitId: AppConfig.admobAppOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (_) {
          _appOpenAd = null;
        },
      ),
    );
  }

  Future<void> showAppOpenAdIfAvailable() async {
    final ad = _appOpenAd;
    if (_isPro ||
        ad == null ||
        _lastAppOpenShown != null &&
            DateTime.now().difference(_lastAppOpenShown!) < _appOpenCooldown) {
      return;
    }

    _appOpenAd = null;
    _lastAppOpenShown = DateTime.now();
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (_) => _loadAppOpenAd(),
      onAdFailedToShowFullScreenContent: (ad, error) => _loadAppOpenAd(),
    );
    await ad.show();
  }

  /// Loads and shows an interstitial immediately, skipping Pro users.
  /// Future apps decide when to call this (never guess full-screen moments).
  Future<void> showInterstitialIfAvailable() async {
    if (_isPro) return;
    await InterstitialAd.load(
      adUnitId: AppConfig.admobInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback<
            InterstitialAd
          >(
            onAdDismissedFullScreenContent: (_) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  /// Cadence-guarded interstitial helper.
  ///
  /// The app records a "pending" count every time it calls this method at a
  /// natural break and only shows an ad once the policy allows it (cooldown,
  /// frequency, and app-open guard). Free users only; Pro never sees ads.
  Future<void> maybeShowInterstitialIfDue({
    required SharedPreferences prefs,
    InterstitialAdPolicy policy = const InterstitialAdPolicy(),
  }) async {
    if (_isPro) return;

    final now = DateTime.now();
    final lastShownMs = prefs.getInt(_lastInterstitialKey) ?? 0;
    final pending =
        (prefs.getInt(_pendingInterstitialCountKey) ?? 0) + 1;
    final shouldShow = policy.shouldShow(
      isPro: false,
      lastInterstitialAt: lastShownMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastShownMs),
      now: now,
      pendingCount: pending,
      lastAppOpenAt: _lastAppOpenShown,
    );
    if (!shouldShow) {
      await prefs.setInt(_pendingInterstitialCountKey, pending);
      return;
    }

    await prefs.setInt(_lastInterstitialKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_pendingInterstitialCountKey, 0);
    await showInterstitialIfAvailable();
  }
}

/// Pure, testable decision logic for cadence-guarded interstitials.
///
/// The policy only knows the paid entitlement and timing; the app decides the
/// exact placement (natural breaks only).
class InterstitialAdPolicy {
  const InterstitialAdPolicy({
    this.cooldown = const Duration(minutes: 10),
    this.afterAppOpenGuard = const Duration(minutes: 2),
    this.every = 3,
  });

  final Duration cooldown;
  final Duration afterAppOpenGuard;
  final int every;

  bool shouldShow({
    required bool isPro,
    required DateTime now,
    required int pendingCount,
    DateTime? lastInterstitialAt,
    DateTime? lastAppOpenAt,
  }) {
    if (isPro) return false;
    final lastShown = lastInterstitialAt;
    if (lastShown != null &&
        now.difference(lastShown) < cooldown) {
      return false;
    }
    final lastAppOpen = lastAppOpenAt;
    if (lastAppOpen != null &&
        now.difference(lastAppOpen) < afterAppOpenGuard) {
      return false;
    }
    return pendingCount >= every;
  }
}
