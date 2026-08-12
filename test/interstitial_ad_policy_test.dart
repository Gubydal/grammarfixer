import 'package:app_starter/features/ads/data/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 12);
  const policy = InterstitialAdPolicy();

  group('InterstitialAdPolicy', () {
    test('shows after the configured frequency', () {
      expect(
        policy.shouldShow(isPro: false, now: now, pendingCount: 3),
        isTrue,
      );
    });

    test('waits until the frequency threshold', () {
      expect(
        policy.shouldShow(isPro: false, now: now, pendingCount: 2),
        isFalse,
      );
    });

    test('respects the cooldown', () {
      expect(
        policy.shouldShow(
          isPro: false,
          now: now,
          pendingCount: 3,
          lastInterstitialAt: now.subtract(const Duration(minutes: 9)),
        ),
        isFalse,
      );
    });

    test('does not show right after an app-open ad', () {
      expect(
        policy.shouldShow(
          isPro: false,
          now: now,
          pendingCount: 3,
          lastAppOpenAt: now.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });

    test('Pro users never see interstitials', () {
      expect(
        policy.shouldShow(isPro: true, now: now, pendingCount: 100),
        isFalse,
      );
    });
  });
}
