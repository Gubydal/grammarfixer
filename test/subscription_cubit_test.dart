import 'package:app_starter/features/subscriptions/presentation/cubits/subscription_cubit.dart';
import 'package:app_starter/features/subscriptions/presentation/cubits/subscription_states.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forcePro emits loaded Pro without checking RevenueCat', () {
    final cubit = SubscriptionCubit(
      attachRevenueCatListener: false,
      forcePro: true,
      isProCheck: () async => throw StateError('must not be called'),
    );

    expect(cubit.state, isA<SubscriptionLoaded>());
    expect((cubit.state as SubscriptionLoaded).isPro, isTrue);
  });

  test('checkProStatus emits loaded with the injected pro status', () async {
    final cubit = SubscriptionCubit(
      attachRevenueCatListener: false,
      isProCheck: () async => false,
    );

    await cubit.checkProStatus();

    expect(cubit.state, isA<SubscriptionLoaded>());
    expect((cubit.state as SubscriptionLoaded).isPro, isFalse);
  });

  test('checkProStatus surfaces errors', () async {
    final cubit = SubscriptionCubit(
      attachRevenueCatListener: false,
      isProCheck: () async => throw Exception('offline'),
    );

    await cubit.checkProStatus();

    expect(cubit.state, isA<SubscriptionError>());
  });
}
